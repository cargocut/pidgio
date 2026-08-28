(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describes the errors that can be propagated by the server (and
    provides their Pidgin decoders). *)

(** {1 Types} *)

(** All errors that may occur on a Pidgio server. *)
type t

(** {1 Building errors}

    There are a number of parameters that are common to the process of
    generating errors:

    - [id] the ID (int), which is optional and provided by the client.
    - [body] The request sent as a string. The entire request as a
      string. *)

(** [parse_error ~body] when the [body] request could not be parsed. *)
val parse_error : body:string -> t

(** [invalid_request ~body validation_error] when the incoming request
    can't be validated. *)
val invalid_request : body:string -> Pidgin.Check.value_error -> t

(** [method_not_found ?id ~body meth] when then given [meth] of the
    request [id] is not available. *)
val method_not_found : ?id:int -> body:string -> string list -> t

(** [invalid_params ?id ~body validation_error] when the incoming
    request of [id] can't validate params. *)
val invalid_params : ?id:int -> body:string -> Pidgin.Check.value_error -> t

(** [internal_error ?id ~body message] when an internal error for the
    request of id [id] it is raised with the given [message]. *)
val internal_error : ?id:int -> body:string -> string -> t

(** [custom_error ?id ~body ~code ?message ()] when an error occurs on
    the server side. It is used of user-defined errors. [code] should
    start at [0] (the function did the offset addition). *)
val custom_error
  :  ?id:int
  -> body:string
  -> code:int
  -> ?message:string
  -> unit
  -> t

(** {1 Serialization}

    From the server's perspective, errors must be serialized only
    because they are consumed by another client. *)

(** [to_pidgin err] serialize the given [err] into a Pidgin
    representation. *)
val to_pidgin : t Pidgin.Repr.conv
