(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

module Sigs = Sigs
module Util = Util
module Error = Error
module Request = Request
module Response = Response
module Route = Route
module Make = Make
module Json = Make.Json
module Server = Make.Server

(* Type aliases *)

type pidgin = Pidgin.Repr.t
type 'params request = 'params Request.t
type 'a args = 'a Highway.Args.t
type 'a hole = 'a Highway.Hole.t
type ('a, 'b) pattern = ('a, 'b) Highway.Pattern.t
type ('a, 'b) path = ('a, 'b) Highway.Path.t
type 'a params = 'a Pidgin.Prism.t
type ('hole, 'params) route = ('hole, 'params) Route.t

(* Pattern definition *)

let s = Highway.Pattern.s
let string = Highway.Pattern.string
let int = Highway.Pattern.int
let float = Highway.Pattern.float
let char = Highway.Pattern.char
let bool = Highway.Pattern.bool
let opt = Highway.Pattern.opt

(* Params definition *)

let params = Pidgin.Prism.make

(* Routes *)

let route = Route.make
