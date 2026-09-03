(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** A library for writing {{:https://www.jsonrpc.org/specification}
    JSON-RPC 2.0} servers that communicate over a process's standard
    streams rather than a socket. You declare a set of methods (using
    {{:https://github.com/cargocut/highway} Highway}), each with its
    own parameter decoding and result encoding (using
    {{:https://github.com/cargocut/pidgin} Pidgin}), and the library
    handles the rest of the protocol: reading framed messages from
    [stdin], parsing and validating envelopes, routing requests to
    handlers, distinguishing requests from notifications, serialising
    results and errors back to [stdout], and reporting malformed input
    with the standard error codes.

    This is the transport used by the Language Server Protocol and by
    editor tooling generally, where the client spawns the server as a
    child process and speaks to it through pipes.

    Every JSONRPC entry-point is parametrized by a Highway [path]
    (instead of just a method) and the handler of an entrypoint use
    {{:https://github.com/cargocut/primavera} Primavera} for
    abstracting dependencies/effects.

    This makes it possible to quickly set up servers that interact
    with other programs (such as Emacs). *)

(** {1 Buidling JSON Handler}

    The library does not handle JSON decoding/encoding; you can
    provide your own implementation that adheres to the
    {{!module-type:Sigs.JSON} signature, or use the [pidgio-yojson]
    package, which is based on
    {{:https://ocaml.org/p/yojson/3.0.0/doc/yojson/Yojson/Basic/index.html}
    [Yojson.Basic]}. *)

module Json = Make.Json

(** {1 Building Server Handler}

    As with JSON, you can choose to define your own stream
    provider. To be generic, the module must implement a
    {{!module-type:Primavera.Sig.Req.S1} Monad} (which can be the
    identity monad) and {{!module-type:Sigs.IO} stream read/write
    primitives}. You can just use [pidgio-unix] (that just relies on
    the [Unix] module) or [pidgio-eio] (based on
    {{:https://ocaml.org/p/eio/latest} Eio}). *)

module Server = Make.Server

(**  {1 Big Picture}

     First, we're going to set up a server on [Unix] and [Yojson]:

     {@ocaml[
     module Server = Pidgio_unix.Make (Pidgio_yojson)
     ]}

     The [Server] module provides a comprehensive set of tools for
     describing the server's behavior:

     - Functions for describing routes and their parameters

     - An [Eff] module that provides a [Primavera] instance for the
       monad used to describe the IO layer.

     Now we can describe our first service:

     {@ocaml[
     let ping =
       let open Server in
       straight
         ([ s "ping" ] & ignore_param)
         ~to_pidgin:Pidgin.Repr.string (* The way to encode the result. *)
         (fun [ (* Highway args *) ] () (* <- param *) ->
            (* Perform an effect for the flex *)
            let* () = Eff.perform (fun h -> h#play_ping_pong) in
            (* Write the final result... pong, that will be included
               into a proper response. *)
            return "pong")
     ;;
     ]}

     We can now start our server, specifying the list of services we
     want to support and the handler to interpret the events. In this
     case, we have only one:

     {@ocaml[
     let () =
       let handler =
         object
           method play_ping_pong = (* Does nothing. lol *) ()
         end
       in
       S.run ~handler [ ping ]
     ;;
     ]}

     You can refer to the tests for some slightly more challenging
     examples. *)

(** {1 Internal modules} *)

module Sigs = Sigs
module Util = Util
module Error = Error
module Request = Request
module Response = Response
module Route = Route
module Make = Make
