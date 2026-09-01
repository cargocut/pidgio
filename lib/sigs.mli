(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Reusable Interfaces. *)

module type IO = sig
  (** Allows for (potentially) generic composition with sources
      (stdin/stdout). *)

  (** Should be a {!module-type:Primavera.Sig.Req.S1}. *)
  type 'a t

  (** In Channel *)
  type input

  (** Out Channel *)
  type output

  (** [read_line in_channel] read the given [in_channel], return [None] at
      the end of the line. *)
  val read_line : input -> string option t

  (** [read_exactly in_channel length] read the given [in_channel] for
      exactly [length]. *)
  val read_exactly : input -> int -> string option t

  (** [write out_channel str] write [str] on the given
      [out_channel]. *)
  val write : output -> string -> unit t

  (** [flush out_channel] flush the given [out_channel]. *)
  val flush : output -> unit t
end

module type SERVER = sig
  (** A server provides all the types and functions needed to describe
      a server (in terms of processes) for managing JSON-RPC
      services. *)

  (** The main type of the server. *)
  type 'a t

  (** In Channel *)
  type input

  (** Out Channel *)
  type output

  (** {1 Primavera}

      The server wrap a Primavera dependency injection on top of the
      given monad ['a t]. *)

  module Primavera : Primavera.Sig.S1 with type 'a output = 'a t

  (** {1 Types} *)

  (** Hold a value of type ['a] that needs ['handler] to be
      performed. *)
  type ('a, 'handler) eff = ('a, 'handler) Primavera.t

  (** Service should return a pidgin expression. *)
  type pidgin = Pidgin.Repr.t

  (** [args] type describes a heterogeneous list used to generate links
      associated with a route. It can also serve as a controller
      parameter. *)
  type 'a args = 'a Highway.Args.t

  (** [hole] describes an arbitrary value that can be serialized or
      deserialized. They are used to describe route patterns that
      introduce variables. *)
  type 'a hole = 'a Highway.Hole.t

  (** [pattern] is a path fragment. It can be either a constant value
      (using the {!val:s} function) or a placeholder that introduces a
      variable (using {!type:hole}) into the path. *)
  type ('a, 'b) pattern = ('a, 'b) Highway.Pattern.t

  (** [path] is a heterogeneous list of {{!type:pattern} patterns}
      (which introduces holes in the final type signature). *)
  type ('a, 'b) path = ('a, 'b) Highway.Path.t

  (** [params] is a prism for dealing with route parameters. *)
  type 'a params = 'a Params.t

  (** [route] is a combination of a {!type:path} and {!type:params}. *)
  type ('hole, 'params) route = ('hole, 'params) Route.t

  (** [request] materialize the incomming request. *)
  type 'params request = 'params Request.t

  (** Describes a service capable of producing ['handler']-type
      effects for use in a [Primavera] context. *)
  type 'handler service

  (** {1 Building services} *)

  (** [straight] Describes a service that is not supposed to fail. *)
  val straight
    :  ?precondition:(pidgin request -> bool)
    -> ?postcondition:('a args -> 'params -> 'params request -> bool)
    -> to_pidgin:('a args -> 'params -> 'params request -> 'result -> pidgin)
    -> route:('a, 'params) route
    -> ('a args -> 'params -> 'params request -> ('result, 'handler) eff)
    -> 'handler service

  (** [failable] Describes a service that can fail. *)
  val failable
    :  ?precondition:(pidgin request -> bool)
    -> ?postcondition:('a args -> 'params -> 'params request -> bool)
    -> to_pidgin:('a args -> 'params -> 'params request -> 'result -> pidgin)
    -> to_error:('a args -> 'params -> 'params request -> 'error -> Error.t)
    -> route:('a, 'params) route
    -> ('a args
        -> 'params
        -> 'params request
        -> (('result, 'error) result, 'handler) eff)
    -> 'handler service

  (** [run in_channel out_channel ~handler services] Runs the server
      for a given [handler] and a list of given [services].*)
  val run
    :  input
    -> output
    -> handler:'handler
    -> 'handler service list
    -> unit t
end

module type JSON = sig
  (** Describes the process of converting a string into JSON. *)

  (** The format describing JSON, like Yojson or Jsont. *)
  type t

  (** Since a JSON-RPC server doesn't provide any information beyond
      "Parsing Error," wrapping the result in an option is
      sufficient. *)
  val from_string : string -> t option

  (** Print the result as a string. *)
  val to_string : t -> string
end

module type JSON_DEVICE = sig
  (** A module that can handle JSON. (The result of applying [JSON] to
      [Make.Json]) *)

  (** [request_from_string s] try to parse [s] as a [Pidgin]
      expression. *)
  val request_from_string : string -> (Pidgin.Repr.t Request.t, Error.t) result

  (** Returns a [Pidgin.Repr.t] into a JSON. *)
  val response_to_string : Pidgin.Repr.t -> string
end
