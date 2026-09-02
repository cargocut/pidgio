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
      |> Request.from_pidgin (fun x -> Ok x)
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
  type 'a params = 'a Pidgin.Prism.t
  type ('path, 'params) route = ('path, 'params) Route.t

  type 'handler service =
    | Service :
        { precondition : pidgin request -> bool
        ; route : ('path, 'params) route
        ; postcondition : 'path args -> 'params -> 'params request -> bool
        ; handler :
            'path args -> 'params -> 'params request -> (pidgin, 'handler) eff
        }
        -> 'handler service

  let make
        ?(precondition = fun _ -> true)
        ?(postcondition = fun _ _ _ -> true)
        ~route
        handler
    =
    Service { precondition; route; postcondition; handler }
  ;;

  let straight ?precondition ?postcondition ~to_pidgin ~route handler =
    make ?precondition ?postcondition ~route (fun args params req ->
      let open Primavera.Syntax in
      let+ result = handler args params req in
      result |> to_pidgin args params req |> Response.from_value req)
  ;;

  let failable ?precondition ?postcondition ~to_pidgin ~to_error ~route handler =
    make ?precondition ?postcondition ~route (fun args params req ->
      let open Primavera.Syntax in
      let+ result = handler args params req in
      match result with
      | Ok result ->
        result |> to_pidgin args params req |> Response.from_value req
      | Error err -> err |> to_error args params req |> Response.from_error req)
  ;;

  let dispatch req services =
    let meth = Request.meth req in
    let rec resume = function
      | [] -> Error (Error.method_not_found meth)
      | Service { precondition; route; postcondition; handler } :: rest ->
        if precondition req
        then (
          match Route.extract_path route req with
          | None -> resume rest
          | Some args ->
            (match Route.extract_params route req with
             | Ok params ->
               let req = Request.map (fun _ -> params) req in
               if postcondition args params req
               then Ok (handler args params req)
               else resume rest
             | Error err -> Error (Error.invalid_params err)))
        else resume rest
    in
    resume services
  ;;

  let one_of req services =
    match dispatch req services with
    | Ok computation -> computation
    | Error err -> Primavera.return @@ Error.to_pidgin err
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
    | Error err -> err |> Response.from_error Request.dummy |> M.return
    | Ok req -> Primavera.run ~handler (one_of req) services
  ;;

  let run input output ~handler services =
    let rec loop () =
      let* state = read_frame input in
      match state with
      | Eof -> M.return 1
      | Malformed _ ->
        let result =
          Error.parse_error
          |> Response.from_error Request.dummy
          |> Json.response_to_string
        in
        let* () = D.write output result in
        let* () = D.flush output in
        M.return 2
      | Body body ->
        let* result = handle_body handler services body in
        let result = result |> Json.response_to_string in
        let* () = D.write output result in
        let* () = D.flush output in
        loop ()
    in
    loop ()
  ;;
end
