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

  (** [param] is a prism for dealing with route parameters. *)
  type 'a param = 'a Pidgin.Prism.t

  (** [route] is a combination of a {!type:path} and {!type:param}. *)
  type ('hole, 'param) route = ('hole, 'param) Route.t

  (** [request] materialize the incomming request. *)
  type 'param request = 'param Request.t

  (** Describes a service capable of producing ['handler']-type
      effects for use in a [Primavera] context. *)
  type 'handler service

  (** {1 Describing patterns} *)

  (** {2 Literal Pattern} *)

  (** [s value] describes a {i Literal} pattern, a constant that does
      not introduce a variable into a pattern. *)
  val s : string -> ('a, 'a) pattern

  (** {2 Hole Pattern}

      You can define your own patterns using {!module:Hole} and
      {!module:Pattern}. *)

  (** Describes a pattern that introduces a variable of type
      [string]. *)
  val string : (string -> 'a, 'a) pattern

  (** Describes a pattern that introduces a variable of type [int]. *)
  val int : (int -> 'a, 'a) pattern

  (** Describes a pattern that introduces a variable of type [float]. *)
  val float : (float -> 'a, 'a) pattern

  (** Describes a pattern that introduces a variable of type [char]. *)
  val char : (char -> 'a, 'a) pattern

  (** Describes a pattern that introduces a variable of type [bool]. *)
  val bool : (bool -> 'a, 'a) pattern

  (** Describes a potentially empty hole. It use [empty] to define if a
      value is present or not in a route path. *)
  val opt : ?empty:string -> 'a hole -> ('a option -> 'b, 'b) pattern

  (** {1 Param definition} *)

  (** Build a prism for validating/producing parameters. You can build
      complicated param prisms using this function. *)
  val param : conv:'a Pidgin.Repr.conv -> check:'a Pidgin.Check.t -> 'a param

  (** Ignore param *)
  val ignore_param : unit param

  (** Describe a param for [string]. *)
  val string_param : string param

  (** Describe a param for [int]. *)
  val int_param : int param

  (** Describe a param for [float]. *)
  val float_param : float param

  (** Describe a param for [bool]. *)
  val bool_param : bool param

  (** Describe a param for [char]. *)
  val char_param : char param

  (** Describe a param for [list]. *)
  val list_param : 'a param -> 'a list param

  (** Describe a param for [option]. *)
  val opt_param : 'a param -> 'a option param

  (** Describe a param for [pair]. *)
  val pair_param : 'a param -> 'b param -> ('a * 'b) param

  (** {1 Encoders definition}

      {!module:Encoder} are used to {i finalized} a Pidgio Handler. It
      allows to lift ocaml value into pidgin one. For usability
      purpose, an encoder also takes the path parameters, the param
      and the request to have access to all informations. So encoders
      are helpers for dealing with that. But sometime, you do not want
      to deal with path, params and request, so pre-built encoder just
      discard them. It is only useful for {!val:straight'} and
      {!val:failable'}. *)

  (** [encoder conv] is just [fun _ _ _ -> conv]. As for {!val:param},
      you can use this function to quickly build ambitious encoder. *)
  val encoder
    :  'a Pidgin.Repr.conv
    -> 'b args
    -> 'p
    -> 'p request
    -> 'a Pidgin.Repr.conv

  (** Encode null values. *)
  val null_encoder : 'a args -> 'b -> 'b request -> 'c Pidgin.Repr.conv

  (** Encode [string]. *)
  val string_encoder : 'a args -> 'b -> 'b request -> string Pidgin.Repr.conv

  (** Encode [int]. *)
  val int_encoder : 'a args -> 'b -> 'b request -> int Pidgin.Repr.conv

  (** Encode [float]. *)
  val float_encoder : 'a args -> 'b -> 'b request -> float Pidgin.Repr.conv

  (** Encode [char]. *)
  val char_encoder : 'a args -> 'b -> 'b request -> char Pidgin.Repr.conv

  (** Encode [bool]. *)
  val bool_encoder : 'a args -> 'b -> 'b request -> bool Pidgin.Repr.conv

  (** Encode [list]. *)
  val list_encoder
    :  'v Pidgin.Repr.conv
    -> 'a args
    -> 'b
    -> 'b request
    -> 'v list Pidgin.Repr.conv

  (** Encode [option]. *)
  val opt_encoder
    :  'v Pidgin.Repr.conv
    -> 'a args
    -> 'b
    -> 'b request
    -> 'v option Pidgin.Repr.conv

  (** Encode [pair]. *)
  val pair_encoder
    :  'a Pidgin.Repr.conv
    -> 'b Pidgin.Repr.conv
    -> 'c args
    -> 'd
    -> 'd request
    -> ('a * 'b) Pidgin.Repr.conv

  (** Encode [records]. *)
  val record_encoder
    :  ?normalize_keys:bool
    -> 'a args
    -> 'b
    -> 'b request
    -> (string * pidgin) list Pidgin.Repr.conv

  (** For the [~to_error] of {!val:failable} *)
  val error_encoder
    :  ('a -> Error.t)
    -> 'b args
    -> 'c
    -> 'c request
    -> 'a
    -> Error.t

  (** {1 Building routes} *)

  (** [route path param_check] wrap a {!type:path} and a
      {!type:Pidgin.Check.t} for building a route. *)
  val route
    :  ('args, Highway.Void.t) path
    -> 'param param
    -> ('args, 'param) route

  (** {1 Building services} *)

  (** [notify] Describes a straight service that does not output anything. *)
  val notify
    :  ?precondition:(pidgin request -> bool)
    -> ?postcondition:('a args -> 'param -> 'param request -> bool)
    -> route:('a, 'param) route
    -> ('a args -> 'param -> 'param request -> (unit, 'handler) eff)
    -> 'handler service

  (** [straight'] Describes a service that is not supposed to fail. *)
  val straight
    :  ?precondition:(pidgin request -> bool)
    -> ?postcondition:('a args -> 'param -> 'param request -> bool)
    -> to_pidgin:('result -> pidgin)
    -> route:('a, 'param) route
    -> ('a args -> 'param -> 'param request -> ('result, 'handler) eff)
    -> 'handler service

  (** [failable'] Describes a service that can fail. *)
  val failable
    :  ?precondition:(pidgin request -> bool)
    -> ?postcondition:('a args -> 'param -> 'param request -> bool)
    -> to_pidgin:('result -> pidgin)
    -> to_error:('error -> Error.t)
    -> route:('a, 'param) route
    -> ('a args
        -> 'param
        -> 'param request
        -> (('result, 'error) result, 'handler) eff)
    -> 'handler service

  (** {2 With full configuration}

      Those service variation gives to the finalizers ([to_pidgin] and
      [to_error]) the full path expansion including [path], [param]
      and [retquest]. And can be paired with {!module:Encoder}. *)

  (** [straight'] Describes a service that is not supposed to fail. *)
  val straight'
    :  ?precondition:(pidgin request -> bool)
    -> ?postcondition:('a args -> 'param -> 'param request -> bool)
    -> to_pidgin:('a args -> 'param -> 'param request -> 'result -> pidgin)
    -> route:('a, 'param) route
    -> ('a args -> 'param -> 'param request -> ('result, 'handler) eff)
    -> 'handler service

  (** [failable'] Describes a service that can fail. *)
  val failable'
    :  ?precondition:(pidgin request -> bool)
    -> ?postcondition:('a args -> 'param -> 'param request -> bool)
    -> to_pidgin:('a args -> 'param -> 'param request -> 'result -> pidgin)
    -> to_error:('a args -> 'param -> 'param request -> 'error -> Error.t)
    -> route:('a, 'param) route
    -> ('a args
        -> 'param
        -> 'param request
        -> (('result, 'error) result, 'handler) eff)
    -> 'handler service

  (** [run in_channel out_channel ~handler services] Runs the server
      for a given [handler] and a list of given [services].*)
  val run
    :  input
    -> output
    -> handler:'handler
    -> 'handler service list
    -> int t
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
  val request_from_string
    :  string
    -> (Pidgin.Repr.t Request.incomming, Error.t) result

  (** Returns a [Pidgin.Repr.t] into a JSON. *)
  val response_to_string : Pidgin.Repr.t -> string
end
