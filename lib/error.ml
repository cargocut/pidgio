(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type t =
  | Parse_error
  | Invalid_request of Pidgin.Check.value_error
  | Method_not_found of string list
  | Invalid_params of Pidgin.Check.value_error
  | Internal_error of string
  | Custom_error of
      { code : int
      ; message : string option
      }

let parse_error = Parse_error
let invalid_request error = Invalid_request error
let method_not_found meth = Method_not_found meth
let invalid_params error = Invalid_params error
let internal_error message = Internal_error message

let custom_error ~code ?message () =
  let code = 32000 + code in
  Custom_error { code; message }
;;

let mk_code code = 0 - Int.abs code

let mk ?data ~code message =
  let open Pidgin.Repr in
  record
    [ "code", int (mk_code code)
    ; "message", string message
    ; "data", option Fun.id data
    ]
;;

let rec mk_pidgin_error err =
  let open Pidgin.Repr in
  match err with
  | Pidgin.Check.Unexpected_kind { expected; given; value } ->
    record
      [ "message", string "Unexpected kind"
      ; "expected", string (Pidgin.Kind.to_string expected)
      ; "given", string (Pidgin.Kind.to_string given)
      ; "value", value
      ]
  | Invalid_list { errors; value } ->
    record
      [ "message", string "Invalid list"
      ; ( "errors"
        , list_of
            (fun (i, err) ->
               record [ "at", int i; "error", mk_pidgin_error err ])
            (Nel.to_list errors) )
      ; "value", value
      ]
  | Invalid_record { errors; value } ->
    record
      [ "message", string "Invalid list"
      ; "errors", list_of mk_pidgin_record_error (Nel.to_list errors)
      ; "value", value
      ]
  | Unexpected_value { value; message } ->
    record [ "message", string message; "value", option Fun.id value ]

and mk_pidgin_record_error (err : Pidgin.Check.record_error) =
  let open Pidgin.Repr in
  match err with
  | Pidgin.Check.Invalid_field { field = field :: fields; error } ->
    record
      [ "field", string field
      ; "message", string "Invalid field"
      ; "error", mk_pidgin_error error
      ; "aliases", list_of string fields
      ]
  | Missing_field (field :: fields) ->
    record
      [ "field", string field
      ; "message", string "Missing field"
      ; "aliases", list_of string fields
      ]
  | Invalid_subrecord err ->
    record
      [ "message", string "Invalid subrecord"; "error", mk_pidgin_error err ]
;;

let to_pidgin = function
  | Parse_error -> mk ~code:32700 "Parse error"
  | Invalid_request error ->
    let data = mk_pidgin_error error in
    mk ~code:32600 ~data "Invalid request"
  | Method_not_found meth ->
    let data = Pidgin.Repr.(list_of string meth) in
    mk ~code:32601 ~data "Method not found"
  | Invalid_params error ->
    let data = mk_pidgin_error error in
    mk ~code:32602 ~data "Invalid params"
  | Internal_error message -> mk ~code:32603 message
  | Custom_error { code; message } ->
    let data = Pidgin.Repr.(option string message) in
    mk ~data ~code "Server error"
;;

let encode to_err _ _ _ x = to_err x
