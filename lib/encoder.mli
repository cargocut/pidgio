(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Since the [to_pidgin] argument in a service definition takes the
    path, parameters, and request as arguments, this module allows you
    to ignore them to easily build encoders. *)

(** [make conv] converts a [conv] to an encoder. *)
val make
  :  'a Pidgin.Repr.conv
  -> 'b Highway.args
  -> 'p
  -> 'p Request.t
  -> 'a Pidgin.Repr.conv

(** [error] encode for a function that produce an error. *)
val error
  :  ('a -> Error.t)
  -> 'b Highway.args
  -> 'c
  -> 'c Request.t
  -> 'a
  -> Error.t

(** [null] encoder. *)
val null : 'a Highway.args -> 'b -> 'b Request.t -> 'c Pidgin.Repr.conv

(** [int] encoder. *)
val int : 'a Highway.args -> 'b -> 'b Request.t -> int Pidgin.Repr.conv

(** [float] encoder. *)
val float : 'a Highway.args -> 'b -> 'b Request.t -> float Pidgin.Repr.conv

(** [bool] encoder. *)
val bool : 'a Highway.args -> 'b -> 'b Request.t -> bool Pidgin.Repr.conv

(** [string] encoder. *)
val string : 'a Highway.args -> 'b -> 'b Request.t -> string Pidgin.Repr.conv

(** [char] encoder. *)
val char : 'a Highway.args -> 'b -> 'b Request.t -> char Pidgin.Repr.conv

(** [list] encoder. *)
val list
  :  'a Pidgin.Repr.conv
  -> 'b Highway.args
  -> 'c
  -> 'c Request.t
  -> 'a list Pidgin.Repr.conv

(** [record] encoder. *)
val record
  :  ?normalize_keys:bool
  -> 'a Highway.args
  -> 'b
  -> 'b Request.t
  -> (string * Pidgin.Repr.t) list Pidgin.Repr.conv
