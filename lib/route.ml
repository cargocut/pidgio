(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type ('args, 'params) t =
  { params : 'params Params.t
  ; path : ('args, Highway.Void.t) Highway.path
  }

let make path params = { params; path }

let extract_path { path; _ } req =
  let meth = Request.meth req in
  Highway.Path.from_list path meth
;;

let extract_params { params; _ } req =
  let given_params = Request.params req in
  Params.check params given_params
;;
