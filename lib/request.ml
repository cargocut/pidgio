(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type 'a t =
  { meth : string list
  ; id : int option
  ; params : 'a
  }

type 'a incomming =
  | Batch of 'a t list
  | One of 'a t

type pidgin = Pidgin.Repr.t t

let sanitize_path = function
  | "" :: xs | xs -> xs
;;

let make ~meth ?id params = { meth = sanitize_path meth; params; id }
let dummy = make ~meth:[] (Pidgin.Repr.null ())
let meth { meth; _ } = meth
let id { id; _ } = id
let params { params; _ } = params
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

let from_pidgin hole =
  let open Pidgin.Check in
  record (fun fields ->
    let+ () = guard fields "jsonrpc" (string & String.equal "2.0")
    and+ id = opt fields "id" int
    and+ meth = req fields "method" (string & adapt_method)
    and+ params = req fields "params" hole in
    make ?id ~meth params)
;;

let as_incomming hole =
  let open Pidgin.Check in
  (list_of (from_pidgin hole) $ fun x -> Batch x)
  / (from_pidgin hole $ fun x -> One x)
;;
