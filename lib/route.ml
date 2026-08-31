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

let prepare_request { params; path } args p =
  let params = Params.conv params p
  and path = args |> Highway.Path.to_list path |> String.concat "/" in
  path, params
;;

let make_request ?id route a p =
  let meth, params = prepare_request route a p in
  Util.jsonrpc ?id Pidgin.Repr.[ "method", string meth; "params", params ]
;;
