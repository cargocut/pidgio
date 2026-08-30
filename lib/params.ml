(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type 'a t =
  { check : 'a Pidgin.Check.t
  ; conv : 'a Pidgin.Repr.conv
  }

let make check conv = { check; conv }

let invmap new_check new_conv { check; conv } =
  let check x = x |> check |> Result.map new_check
  and conv x = x |> new_conv |> conv in
  { check; conv }
;;

let check { check; _ } x = check x
let conv { conv; _ } x = conv x
