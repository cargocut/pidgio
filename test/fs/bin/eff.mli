(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

include module type of Server.Primavera

class type handler = object
  method ls : Virtfs.Path.t -> string list
  method cat : Virtfs.Path.t -> string
  method exists : Virtfs.Path.t -> bool
  method is_dir : Virtfs.Path.t -> bool
  method is_file : Virtfs.Path.t -> bool
  method write_file : Virtfs.Path.t -> string -> unit
  method delete : Virtfs.Path.t -> unit
end

val ls : Virtfs.Path.t -> (string list, #handler) t
val cat : Virtfs.Path.t -> (string, #handler) t
val exists : Virtfs.Path.t -> (bool, #handler) t
val is_dir : Virtfs.Path.t -> (bool, #handler) t
val write_file : Virtfs.Path.t -> string -> ((unit, unit) result, #handler) t
val delete_file : Virtfs.Path.t -> ((unit, unit) result, #handler) t
val handler : Virtfs.Tree.Simple.t -> handler
