(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describes the errors that can be propagated by the server (and
    provides their Pidgin decoders). *)

(** {1 Types} *)

(** All errors that may occur on a Pidgio server. *)
type t

(** {1 Building errors} *)

(** [parse_error] when the [body] request could not be parsed. *)
val parse_error : t

(** [invalid_request validation_error] when the incoming request
    can't be validated. *)
val invalid_request : Pidgin.Check.value_error -> t

(** [method_not_found meth] when then given [meth] is not available. *)
val method_not_found : string list -> t

(** [invalid_params validation_error] when the incoming request can't
    validate params. *)
val invalid_params : Pidgin.Check.value_error -> t

(** [internal_error message] when an internal error occurs for the
    incomming request.. *)
val internal_error : string -> t

(** [custom_error ~code message ()] when an error occurs on
    the server side. It is used of user-defined errors. [code] should
    start at [0] (the function did the offset addition). *)
val custom_error : code:int -> ?message:string -> unit -> t

(** {1 Helpers} *)

(** {1 Serialization}

    From the server's perspective, errors must be serialized only
    because they are consumed by another client. *)

(** [to_pidgin err] serialize the given [err] into a Pidgin
    representation. *)
val to_pidgin : t Pidgin.Repr.conv

(** [encode error] make an error suitable for a service definition. *)
val encode : ('result -> t) -> 'a -> 'b -> 'c -> 'result -> t
