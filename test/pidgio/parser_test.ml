(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

open struct
  open Pidgio
  open Alcotest

  let valid_content_length1 =
    test_case "Parse a valid content-length header" `Quick (fun () ->
      let expected = Some 42
      and computed = Util.line_as_content_length "Content-Length: 42\r\n\r\n" in
      check (option int) "should be equal" expected computed)
  ;;

  let valid_content_length2 =
    test_case "Parse a valid content-length header" `Quick (fun () ->
      let expected = Some 42876544
      and computed =
        Util.line_as_content_length "Content-Length: 42876544\r\n\r\n"
      in
      check (option int) "should be equal" expected computed)
  ;;

  let valid_content_length3 =
    test_case "Parse a valid content-length header" `Quick (fun () ->
      let expected = Some 42876544
      and computed =
        Util.line_as_content_length "Content-Length: 042876544\r\n\r\n"
      in
      check (option int) "should be equal" expected computed)
  ;;

  let invvalid_content_length1 =
    test_case "Parse an invalid content-length header" `Quick (fun () ->
      let expected = None
      and computed =
        Util.line_as_content_length "content-length: 042876544\r\n\r\n"
      in
      check (option int) "should be equal" expected computed)
  ;;

  let invvalid_content_length2 =
    test_case "Parse an invalid content-length header" `Quick (fun () ->
      let expected = None
      and computed = Util.line_as_content_length "foobar" in
      check (option int) "should be equal" expected computed)
  ;;
end

let cases =
  ( "Parser"
  , [ valid_content_length1
    ; valid_content_length2
    ; valid_content_length3
    ; invvalid_content_length1
    ; invvalid_content_length2
    ] )
;;
