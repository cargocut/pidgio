(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

module Server = Pidgio_unix.Make (Pidgio_yojson)

let ping =
  let open Server in
  straight
    ~to_pidgin:Pidgin.Repr.string
    (route [ s "ping" ] ignore_param)
    (fun [] () _request -> return "pong")
;;

type param =
  { message : string (* The message to echo *)
  ; loudly : bool (* If the flag is set to true, the echo is UPPERCASED *)
  }

let echo_param =
  let conv { message; loudly } =
    let open Pidgin.Repr in
    record [ "message", string message; "loudly", bool loudly ]
  and check =
    let open Pidgin.Check in
    record (fun fields ->
      let+ message = req fields "message" string
      and+ loudly = opt fields "loudly" bool in
      { message; loudly = Option.value ~default:false loudly })
  in
  Server.param ~conv ~check
;;

type response =
  { message : string
  ; loudly : bool
  ; time : float
  }

let response_to_pidgin { message; loudly; time } =
  let open Pidgin.Repr in
  record
    [ "message", string message; "loudly", bool loudly; "time", float time ]
;;

let echo =
  let open Server in
  straight
    ~to_pidgin:response_to_pidgin
    (route [ s "echo" ] echo_param)
    (fun [] { message; loudly } _req ->
       let+ time = Eff.perform (fun h -> h#get_time) in
       let message =
         if loudly then String.uppercase_ascii message else message
       in
       { message; loudly; time })
;;

let () =
  let handler =
    object
      method get_time = Unix.time ()
    end
  in
  Server.run ~handler [ ping; echo ]
;;
