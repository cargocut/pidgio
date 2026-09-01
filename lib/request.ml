(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type 'a t =
  { meth : string list
  ; body : string
  ; id : int option
  ; params : 'a
  }

type pidgin = Pidgin.Repr.t t

let sanitize_path = function
  | "" :: xs | xs -> xs
;;

let make ~meth ~body ?id params =
  { meth = sanitize_path meth; params; id; body }
;;

let dummy ?(body = "") () = make ~meth:[] ~body (Pidgin.Repr.null ())
let meth { meth; _ } = meth
let id { id; _ } = id
let params { params; _ } = params
let body { body; _ } = body
let map f req = { req with params = f req.params }

let adapt_method s =
  let failure () =
    let value = Pidgin.Repr.string s in
    Pidgin.Check.fail_with ~value "Suspicious method"
  in
  match String.split_on_char '?' s with
  | [ x ] | [ x; _ ] ->
    (match String.split_on_char '#' x with
     | [ x ] | [ x; _ ] ->
       x |> String.split_on_char '/' |> sanitize_path |> Result.ok
     | _ -> failure ())
  | _ -> failure ()
;;

let from_pidgin ~body:body_str hole =
  let open Pidgin.Check in
  record (fun fields ->
    let+ () = guard fields "jsonrpc" (string & String.equal "2.0")
    and+ id = opt fields "id" int
    and+ meth = req fields "method" (string & adapt_method)
    and+ params = req fields "params" hole in
    make ?id ~body:body_str ~meth params)
;;
