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
    (M : Primavera.Sig.Req.S1)
    (IO : Sigs.IO with type 'a t = 'a M.t)
    (_ : Sigs.JSON_DEVICE) :
  Sigs.SERVER
  with type 'a t = 'a M.t
   and type input = IO.input
   and type output = IO.output
