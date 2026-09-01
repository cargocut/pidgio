(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** A set of functors for building generic handlers (notably for JSON
    and for describing a server). *)

(** {1 Dealing with JSON}

    To allow a user to choose the JSON library of their choice. *)

module Json
    (D : Sigs.JSON)
    (_ : Pidgin.Driver.SOURCE with type t = D.t)
    (_ : Pidgin.Driver.TARGET with type t = D.t) : Sigs.JSON_DEVICE

(** {1 Dealing with IO}

    To allow a user to choose the IO library of their choice. *)

module Server
    (_ : Sigs.JSON_DEVICE)
    (M : Sigs.MONAD)
    (IO : Sigs.IO with type 'a t = 'a M.t) : sig
  (** A server provides all the types and functions needed to describe
      a server (in terms of processes) for managing JSON-RPC
      services. *)

  (** {1 Primavera}

      The server wrap a Primavera dependency injection on top of the
      given monad [M]. *)

  module Primavera : Primavera.Sig.S1 with type 'a output = 'a M.t

  (** {1 Types} *)

  (** The main type of the server. *)
  type 'a t = 'a M.t

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
    :  IO.input
    -> IO.output
    -> handler:'handler
    -> 'handler service list
    -> unit t
end
