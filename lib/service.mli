(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describes the services associated with routes. *)

(** {1 Types} *)

(** Since Pidgio already makes a lot of assumptions—notably that the
    user is using Pidgin and Primavera—we've hypocritically configured
    the response to let the user choose their own JSON library. *)
type 'response t

(** {1 Building services} *)

val make
  :  ?precondition:(Request.pidgin -> bool)
  -> ?postcondition:('args Highway.args -> 'params -> 'params Request.t -> bool)
  -> route:('args, 'params) Route.t
  -> to_pidgin:('when_succeed -> Pidgin.Repr.t)
  -> to_error:('when_error -> Error.t)
  -> ('args Highway.args
      -> 'params
      -> 'params Request.t
      -> (('when_succeed, 'when_error) result, 'handler) Primavera.t)
  -> (Pidgin.Repr.t, 'handler) Primavera.t t
