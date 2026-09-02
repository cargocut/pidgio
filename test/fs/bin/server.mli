(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** A simple IO server on top of Unix and Yojson. *)

include module type of Pidgio_unix.Make (Pidgio_yojson)
