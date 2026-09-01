(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

include
  Pidgio.Json
    (struct
      type t = Yojson.Basic.t

      let to_string x = Yojson.Basic.to_string x

      let from_string s =
        try Some (Yojson.Basic.from_string s) with
        | _ -> None
      ;;
    end)
    (Pidgin.Driver.Yojson)
    (Pidgin.Driver.Yojson)
