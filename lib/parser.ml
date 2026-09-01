(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

let line_as_content_length s =
  match String.split_on_char ':' s with
  | [ "Content-Length"; len ] -> int_of_string_opt (String.trim len)
  | _ -> None
;;
