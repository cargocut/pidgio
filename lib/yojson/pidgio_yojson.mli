(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describes a device for parsing JSON using the
    {{:https://ocaml.org/p/yojson/3.0.0/doc/yojson/Yojson/Basic/index.html}
    Yojson library} ([Basic]). *)

include Pidgio.Sigs.JSON_DEVICE (** @inline *)
