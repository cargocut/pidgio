(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** {1 Buidling JSON Handler} *)

module Json = Make.Json

(** {1 Building Server Handler} *)

module Server = Make.Server

(** {1 Internal modules} *)

module Sigs = Sigs
module Util = Util
module Error = Error
module Request = Request
module Response = Response
module Route = Route
module Make = Make
module Encoder = Encoder
