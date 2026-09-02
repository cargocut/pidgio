(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let make
  :  'a Pidgin.Repr.conv
  -> _ Highway.args
  -> 'p
  -> 'p Request.t
  -> 'a Pidgin.Repr.conv
  =
  fun e _ _ _ -> e
;;

let string a p r = make Pidgin.Repr.string a p r
let null a p r = make Pidgin.Repr.null a p r
let int a p r = make Pidgin.Repr.int a p r
let float a p r = make Pidgin.Repr.float a p r
let bool a p r = make Pidgin.Repr.bool a p r
let char a p r = make Pidgin.Repr.char a p r
let list v a p r = make (Pidgin.Repr.list_of v) a p r

let record ?normalize_keys a p r =
  make (Pidgin.Repr.record ?normalize_keys) a p r
;;
