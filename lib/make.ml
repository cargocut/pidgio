(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

module Json
    (D : Sigs.JSON)
    (S : Pidgin.Driver.SOURCE with type t = D.t)
    (T : Pidgin.Driver.TARGET with type t = D.t) =
struct
  let request_from_string str =
    match D.from_string str with
    | None -> Error Error.parse_error
    | Some body ->
      body
      |> S.translate_to_pidgin
      |> Request.as_incomming (fun x -> Ok x)
      |> Result.map_error (fun err -> Error.invalid_request err)
  ;;

  let response_to_string pidgin_repr =
    let str = pidgin_repr |> T.translate_from_pidgin |> D.to_string in
    let len = String.length str in
    "Content-Length: " ^ string_of_int len ^ "\r\n\r\n" ^ str
  ;;
end

module Server
    (M : Primavera.Sig.Req.S1)
    (D : Sigs.IO with type 'a t = 'a M.t)
    (Json : Sigs.JSON_DEVICE) =
struct
  module Primavera = Primavera.Make.S1 (M)

  type input = D.input
  type output = D.output
  type 'a t = 'a M.t
  type ('a, 'handler) eff = ('a, 'handler) Primavera.t
  type pidgin = Pidgin.Repr.t
  type 'a request = 'a Request.t
  type 'a hole = 'a Highway.Hole.t
  type 'a args = 'a Highway.args
  type ('a, 'b) pattern = ('a, 'b) Highway.Pattern.t
  type ('a, 'b) path = ('a, 'b) Highway.Path.t
  type 'a param = 'a Pidgin.Prism.t
  type ('path, 'param) route = ('path, 'param) Route.t

  type 'handler service =
    | Service :
        { precondition : pidgin request -> bool
        ; is_notif : bool
        ; route : ('path, 'param) route
        ; postcondition : 'path args -> 'param -> 'param request -> bool
        ; handler :
            'path args -> 'param -> 'param request -> (pidgin, 'handler) eff
        }
        -> 'handler service

  let make
        ?(precondition = fun _ -> true)
        ?(postcondition = fun _ _ _ -> true)
        ?(is_notif = false)
        ~route
        handler
    =
    Service { precondition; route; postcondition; handler; is_notif }
  ;;

  let straight ?precondition ?postcondition ~to_pidgin route handler =
    make ?precondition ?postcondition ~route (fun args param req ->
      let open Primavera.Syntax in
      let+ result = handler args param req in
      result |> to_pidgin |> Response.from_value req)
  ;;

  let failable ?precondition ?postcondition ~to_pidgin ~to_error route handler =
    make ?precondition ?postcondition ~route (fun args param req ->
      let open Primavera.Syntax in
      let+ result = handler args param req in
      match result with
      | Ok result -> result |> to_pidgin |> Response.from_value req
      | Error err -> err |> to_error |> Response.from_error req)
  ;;

  let notify ?precondition ?postcondition route handler =
    make
      ~is_notif:true
      ?precondition
      ?postcondition
      ~route
      (fun args param req ->
         let open Primavera.Syntax in
         let+ () = handler args param req in
         Pidgin.Repr.null () |> Response.from_value req)
  ;;

  let dispatch req services =
    let meth = Request.meth req in
    let rec resume = function
      | [] -> Error (Error.method_not_found meth)
      | Service { precondition; route; postcondition; handler; is_notif }
        :: rest ->
        if precondition req && Bool.equal (Request.is_notification req) is_notif
        then (
          match Route.extract_path route req with
          | None -> resume rest
          | Some args ->
            (match Route.extract_param route req with
             | Ok param ->
               let req = Request.map (fun _ -> param) req in
               if postcondition args param req
               then Ok (handler args param req)
               else resume rest
             | Error err -> Error (Error.invalid_params err)))
        else resume rest
    in
    resume services
  ;;

  let one_of req services =
    let id = Request.id req in
    let open Primavera in
    match dispatch req services with
    | Ok computation ->
      let+ result = computation in
      Option.map (fun _ -> result) id
    | Error err ->
      Primavera.return @@ Option.map (fun _ -> Error.to_pidgin err) id
  ;;

  type header_error =
    | Negative_content_length
    | No_content_length

  type state =
    | Eof
    | Malformed of header_error
    | Body of string

  let ( let* ) = M.bind

  let read_frame input =
    let rec aux already_seen len =
      let* line = D.read_line input in
      match line with
      | None -> M.return Eof
      | Some line ->
        (match String.trim line with
         | "" when not already_seen ->
           (* A simple separator, shoudl not happen btw. *)
           aux already_seen len
         | "" ->
           (* We have seen the content-length and we remove the line. *)
           (match len with
            | None -> M.return (Malformed No_content_length)
            | Some n when n < 0 -> M.return (Malformed Negative_content_length)
            | Some n ->
              let* body = D.read_exactly input n in
              (match body with
               | None ->
                 (* Early termination of stream. *)
                 M.return Eof
               | Some body -> M.return (Body body)))
         | line ->
           let hdlen =
             match Util.line_as_content_length line with
             | Some n -> Some n
             | None -> len
           in
           aux true hdlen)
    in
    aux false None
  ;;

  let handle_body handler services body =
    match Json.request_from_string body with
    | Error err ->
      err |> Response.from_error Request.dummy |> Option.some |> M.return
    | Ok (One req) -> Primavera.run ~handler (one_of req) services
    | Ok (Batch reqs) ->
      let eff () =
        let open Primavera in
        let+ result = List.traverse (fun req -> one_of req services) reqs in
        match Stdlib.List.filter_map (fun x -> x) result with
        | [] -> None
        | xs -> Some (Pidgin.Repr.list xs)
      in
      Primavera.run ~handler eff ()
  ;;

  let run input output ~handler services =
    let rec loop () =
      let* state = read_frame input in
      match state with
      | Eof -> M.return 1
      | Malformed _ -> M.return 2
      | Body body ->
        let* result = handle_body handler services body in
        (match result with
         | None ->
           (* No ID so we are in a notification case *)
           loop ()
         | Some result ->
           (* Some results *)
           let result = result |> Json.response_to_string in
           let* () = D.write output result in
           let* () = D.flush output in
           loop ())
    in
    loop ()
  ;;

  (* Pattern definition *)

  let s = Highway.Pattern.s
  let string = Highway.Pattern.string
  let int = Highway.Pattern.int
  let float = Highway.Pattern.float
  let char = Highway.Pattern.char
  let bool = Highway.Pattern.bool
  let opt = Highway.Pattern.opt

  (* Param definition *)

  let param = Pidgin.Prism.make

  let ignore_param =
    param ~check:(Pidgin.Check.const ()) ~conv:(fun _ -> Pidgin.Repr.null ())
  ;;

  let string_param = param ~check:Pidgin.Check.string ~conv:Pidgin.Repr.string
  let int_param = param ~check:Pidgin.Check.int ~conv:Pidgin.Repr.int
  let float_param = param ~check:Pidgin.Check.float ~conv:Pidgin.Repr.float
  let bool_param = param ~check:Pidgin.Check.bool ~conv:Pidgin.Repr.bool
  let char_param = param ~check:Pidgin.Check.char ~conv:Pidgin.Repr.char

  let list_param f =
    param
      ~check:(Pidgin.Check.list_of (Pidgin.Prism.check f))
      ~conv:(Pidgin.Repr.list_of (Pidgin.Prism.conv f))
  ;;

  let opt_param f =
    param
      ~check:(Pidgin.Check.option (Pidgin.Prism.check f))
      ~conv:(Pidgin.Repr.option (Pidgin.Prism.conv f))
  ;;

  let pair_param a b =
    let a_conv = Pidgin.Prism.conv a
    and b_conv = Pidgin.Prism.conv b
    and a_check = Pidgin.Prism.check a
    and b_check = Pidgin.Prism.check b in
    param
      ~check:(Pidgin.Check.pair a_check b_check)
      ~conv:(Pidgin.Repr.pair a_conv b_conv)
  ;;

  (* Routes *)

  let route = Route.make

  (* Infix operators *)

  module Infix = struct
    let ( <&> ) path prism = Route.make path prism
    let ( ~& ) path = path <&> ignore_param
  end

  include Infix
end
