(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describes the services associated with routes. *)

(** {1 Types} *)

(** Since Pidgio already makes a lot of assumptions—notably that the
    user is using Pidgin and Primavera—we've hypocritically configured
    the response to let the user choose their own JSON library. *)
type 'response t

(** {1 Building services}

    Since the handler must be shared by all services to be routed, the
    "restriction" value does not specify the handler type, which
    is... normal. *)

(** [make ?precondition ?postcondition ~route ~to_pidgin ~to_error handler]
    Build a service using the same logic as Highway. The result is
    finalized by the [to_pidgin] and [to_error] functions (which take
    the same arguments as the handler). *)
val make
  :  ?precondition:(Request.pidgin -> bool)
  -> ?postcondition:('args Highway.args -> 'params -> 'params Request.t -> bool)
  -> route:('args, 'params) Route.t
  -> to_pidgin:
       ('args Highway.args
        -> 'params
        -> 'params Request.t
        -> 'when_succeed
        -> Pidgin.Repr.t)
  -> to_error:
       ('args Highway.args
        -> 'params
        -> 'params Request.t
        -> 'when_error
        -> Error.t)
  -> ('args Highway.args
      -> 'params
      -> 'params Request.t
      -> (('when_succeed, 'when_error) result, 'handler) Primavera.t)
  -> (Pidgin.Repr.t, 'handler) Primavera.t t

(** {1 Routing} *)

(** [one_of request services] chose one service related to the given
    request. *)
val one_of
  :  Pidgin.Repr.t Request.t
  -> (Pidgin.Repr.t, 'handler) Primavera.t t list
  -> (Pidgin.Repr.t, 'handler) Primavera.t
