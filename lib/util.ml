(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let jsonrpc ?id value =
  Pidgin.Repr.(
    record ([ "jsonrpc", string "2.0"; "id", option int id ] @ value))
;;
