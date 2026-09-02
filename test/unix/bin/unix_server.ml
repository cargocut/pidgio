(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

module S = Pidgio_unix.Make (Pidgio_yojson)

let ignored =
  S.param ~check:(Pidgin.Check.const ()) ~conv:(fun _ -> Pidgin.Repr.null ())
;;

let simple_message =
  S.param
    ~check:
      Pidgin.Check.(
        record (fun fields ->
          let+ message = req fields "message" string
          and+ shout = opt fields "shout" bool in
          message, Option.value ~default:false shout))
    ~conv:
      Pidgin.Repr.(
        fun (message, shout) ->
          record [ "message", string message; "shout", bool shout ])
;;

let () =
  let open S in
  run
    ~handler:object end
    [ straight
        ~route:(route [ s "ping" ] ignored)
        ~to_pidgin:Pidgio.Encoder.string
        (fun [] () _ -> Primavera.return "pong")
    ; straight
        ~route:(route [ s "echo" ] simple_message)
        ~to_pidgin:Pidgio.Encoder.string
        (fun [] (message, shout) _req ->
           let open Primavera in
           let message =
             if shout then String.uppercase_ascii message else message
           in
           return message)
    ]
;;
