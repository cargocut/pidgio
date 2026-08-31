(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** [jsonrpc ?id fields] builds a JSON-RPC header. *)
val jsonrpc : ?id:int -> (string * Pidgin.Repr.t) list -> Pidgin.Repr.t
