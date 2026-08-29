(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let from_error req error =
  error |> Error.with_id (Request.id req) |> Error.to_pidgin
;;

let from_value req value =
  let open Pidgin.Repr in
  record
    [ "jsonrpc", string "2.0"
    ; "id", option int (Request.id req)
    ; "result", value
    ]
;;
