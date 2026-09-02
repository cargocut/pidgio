(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Allows you to create an Eio Pidgio server. *)

module Make (_ : Pidgio.Sigs.JSON_DEVICE) : sig
  include Pidgio.Sigs.SERVER with type 'a t = 'a

  (** [run ~handler services] launch a Pidgio server for the given
      list of [services] under the dedicated [handler]. *)
  val run
    :  handler:(Eio_unix.Stdenv.base -> 'handler)
    -> 'handler service list
    -> unit
end
