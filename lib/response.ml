(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let result req tail = Util.jsonrpc ?id:(Request.id req) tail

let from_error req error =
  let data = Error.to_pidgin error in
  result req [ "error", data ]
;;

let from_value req value = result req [ "result", value ]
