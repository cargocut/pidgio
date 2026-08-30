(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describes the conversion/validation ISO for route parameters. *)

(** {1 Types} *)

(** An iso that allows to check or convert ['a] values. *)
type 'a t

(** {1 Utils} *)

(** [make check conv] build an iso for params. *)
val make : 'a Pidgin.Check.t -> 'a Pidgin.Repr.conv -> 'a t

(** [invmap from_a to_a] map over iso. *)
val invmap : ('a -> 'b) -> ('b -> 'a) -> 'a t -> 'b t

(** [check device value] perform [check] on value. *)
val check : 'a t -> 'a Pidgin.Check.t

(** [conv device value] perform [conv] on value. *)
val conv : 'a t -> 'a Pidgin.Repr.conv
