(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** A request is what the Pidgio router interprets to determine which
    service to run. *)

(** {1 Types} *)

(** The query is configured based on the type of parameters to allow
    for multiple stages in the service selection. *)
type 'a t

(** A request from a pidgin result. *)
type pidgin = Pidgin.Repr.t t

(** {1 Build requests} *)

(** [make ?id ~meth params] build a request object. *)
val make : meth:string list -> body:string -> ?id:int -> 'a -> 'a t

(** [dummy] is a dummy request for errors before having any
    information. *)
val dummy : ?body:string -> unit -> pidgin

(** {1 Accessors} *)

(** [meth req] returns the list that define the method of the
    request. *)
val meth : 'a t -> string list

(** [id req] returns the ID of the incomming request. *)
val id : 'a t -> int option

(** [params req] returns the params of the incomming request. *)
val params : 'a t -> 'a

(** [body req] returns the body (string representation) of the
    incomming request. *)
val body : 'a t -> string

(** {1 Manipulating request} *)

(** [map f req] map the field parameters of a request. *)
val map : ('a -> 'b) -> 'a t -> 'b t

(** {1 Accessors} *)

(** {1 Deserialization} *)

(** [from_pidgin ~body hole] validate an incoming request using [hole] for
    deserializing parameters. Should be a valid JSONRPC incomming
    request (with the field ["jsonrpc" = "2.0"]). *)
val from_pidgin : body:string -> 'a Pidgin.Check.t -> 'a t Pidgin.Check.t
