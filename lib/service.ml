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

let dispatch body req services =
  let id = Request.id req
  and meth = Request.meth req in
  let rec resume = function
    | [] -> Error (Error.method_not_found ?id ~body meth)
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
           | Error err -> Error (Error.invalid_params ?id ~body err)))
      else resume rest
  in
  resume services
;;
