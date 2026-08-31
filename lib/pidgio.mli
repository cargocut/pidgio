(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** {1 Types}

    Re-exporting utility types to simplify the API. *)

(** Errors that can occurs. *)
type error = Error.t

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

(** [params] is an iso for dealing with route parameters. *)
type 'a params = 'a Params.t

(** [route] is a combination of a {!type:path} and {!type:params}. *)
type ('hole, 'params) route = ('hole, 'params) Route.t

(** [request] materialize the incomming request. *)
type 'params request = 'params Request.t

(** [service] is a controller attached to a {!type:route}. *)
type 'response service = 'response Service.t

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

(** {1 Building routes} *)

(** [route path param_check] wrap a {!type:path} and a
    {!type:Pidgin.Check.t} for building a route. *)
val route
  :  ('args, Highway.Void.t) path
  -> 'params params
  -> ('args, 'params) route

(** {1 Internal modules} *)

module Error = Error
module Request = Request
module Response = Response
module Service = Service
