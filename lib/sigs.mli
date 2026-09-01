(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Reusable Interfaces. *)

(**The purpose of the Monade interface is to generalize several
   behaviors (such as Lwt or Unix) by assuming that anything that is
   not a monad can rely on identity. *)
module type MONAD = Primavera.Sig.Req.S1

module type IO = sig
  (** Allows for (potentially) generic composition with sources
      (stdin/stdout). *)

  (** Should be a {!module-type:MONAD}. *)
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

module type SERVER = sig end
