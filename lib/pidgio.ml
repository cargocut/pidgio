(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

module Error = Error
module Request = Request
module Response = Response
module Params = Params
module Route = Route
module Service = Service

(* Type aliases *)

type ('a, 'handler) eff = ('a, 'handler) Primavera.t
type pidgin = Pidgin.Repr.t
type error = Error.t
type 'params request = 'params Request.t
type 'a args = 'a Highway.Args.t
type 'a hole = 'a Highway.Hole.t
type ('a, 'b) pattern = ('a, 'b) Highway.Pattern.t
type ('a, 'b) path = ('a, 'b) Highway.Path.t
type 'a params = 'a Params.t
type ('hole, 'params) route = ('hole, 'params) Route.t
type 'response service = 'response Service.t

(* Pattern definition *)

let s = Highway.Pattern.s
let string = Highway.Pattern.string
let int = Highway.Pattern.int
let float = Highway.Pattern.float
let char = Highway.Pattern.char
let bool = Highway.Pattern.bool
let opt = Highway.Pattern.opt

(* Params definition *)

let params = Params.make

(* Routes *)

let route = Route.make

(* Services *)

let service = Service.make
