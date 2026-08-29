(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Some helpers for dealing with server's response. *)

(** [from_error req err] returns the corresponding Pidgin
    representation with the probably right ID extracted from the
    request. *)
val from_error : 'a Request.t -> Error.t -> Pidgin.Repr.t

(** [from_value req value] wrap the result into a JSONRPC object. *)
val from_value : 'a Request.t -> Pidgin.Repr.t -> Pidgin.Repr.t
