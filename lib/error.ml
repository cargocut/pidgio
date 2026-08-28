(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

type t =
  | Parse_error of { body : string }
  | Invalid_request of
      { body : string
      ; error : Pidgin.Check.value_error
      }
  | Method_not_found of
      { body : string
      ; id : int option
      ; meth : string list
      }
  | Invalid_params of
      { body : string
      ; id : int option
      ; error : Pidgin.Check.value_error
      }
  | Internal_error of
      { body : string
      ; id : int option
      ; message : string
      }
  | Custom_error of
      { body : string
      ; id : int option
      ; code : int
      ; message : string option
      }

let parse_error ~body = Parse_error { body }
let invalid_request ~body error = Invalid_request { body; error }
let method_not_found ?id ~body meth = Method_not_found { body; id; meth }
let invalid_params ?id ~body error = Invalid_params { id; body; error }
let internal_error ?id ~body message = Internal_error { id; body; message }

let custom_error ?id ~body ~code ?message () =
  let code = 32000 + code in
  Custom_error { id; body; code; message }
;;

let mk_code code = 0 - Int.abs code

let mk ?id ?data ~body ~code message =
  let open Pidgin.Repr in
  record
    [ "jsonrpc", string "2.0"
    ; "id", option int id
    ; ( "error"
      , record
          [ "code", int (mk_code code)
          ; "message", string message
          ; "body", string body
          ; "data", option Fun.id data
          ] )
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
  | Parse_error { body } -> mk ~body ~code:32700 "Parse error"
  | Invalid_request { body; error } ->
    let data = mk_pidgin_error error in
    mk ~body ~code:32600 ~data "Invalid request"
  | Method_not_found { body; id; meth } ->
    let data = Pidgin.Repr.(list_of string meth) in
    mk ~body ~code:32601 ~data ?id "Method not found"
  | Invalid_params { body; id; error } ->
    let data = mk_pidgin_error error in
    mk ?id ~body ~code:32602 ~data "Invalid params"
  | Internal_error { body; id; message } -> mk ?id ~body ~code:32603 message
  | Custom_error { body; id; code; message } ->
    let data = Pidgin.Repr.(option string message) in
    mk ?id ~data ~body ~code "Server error"
;;
