(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type 'response t =
  | Service :
      { precondition : Pidgin.Repr.t Request.t -> bool
      ; route : ('args, 'params) Route.t
      ; postcondition :
          'args Highway.args -> 'params -> 'params Request.t -> bool
      ; handler :
          'args Highway.args -> 'params -> 'params Request.t -> 'response
      }
      -> 'response t

let make
      ?(precondition = fun _ -> true)
      ?(postcondition = fun _ _ _ -> false)
      ~route
      ~to_pidgin
      ~to_error
      handler
  =
  let handler args params req =
    let open Primavera.Syntax in
    let+ result = handler args params req in
    match result with
    | Ok x -> x |> to_pidgin args params req |> Response.from_value req
    | Error err -> err |> to_error args params req |> Response.from_error req
  in
  Service { precondition; postcondition; route; handler }
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
  | Error err ->
    Primavera.return @@ Error.to_pidgin ~body:(Request.body req) err
;;
