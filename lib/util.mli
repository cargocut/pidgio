(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** [jsonrpc ?id fields] builds a JSON-RPC header. *)
val jsonrpc : ?id:int -> (string * Pidgin.Repr.t) list -> Pidgin.Repr.t

(** [line_as_content_length s] try to decode [s] as an header with
    ["Content-Length: size"]. *)
val line_as_content_length : string -> int option
