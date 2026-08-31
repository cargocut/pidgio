(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let result req tail = Util.jsonrpc ?id:(Request.id req) tail

let from_error req error =
  let body = Request.body req in
  let data = Error.to_pidgin ~body error in
  result req [ "error", data ]
;;

let from_value req value = result req [ "result", value ]
