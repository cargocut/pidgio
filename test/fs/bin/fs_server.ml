(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(* An example of a server that interacts with a virtual server
   provided by Virtfs. *)

let path =
  Pidgin.Prism.make
    ~conv:Pidgin.Repr.(using Virtfs.Path.to_string string)
    ~check:Pidgin.Check.(string $ Virtfs.Path.from_string)
;;

let with_content =
  Pidgin.Prism.make
    ~conv:Pidgin.Repr.(pair (Pidgin.Prism.conv path) string)
    ~check:Pidgin.Check.(pair (Pidgin.Prism.check path) string)
;;

module S = Server

let ls =
  let open Pidgio in
  S.straight
    ~route:(route [ s "ls" ] path)
    ~to_pidgin:(Encoder.list Pidgin.Repr.string)
    (fun [] path _req -> Eff.ls path)
;;

let cat =
  let open Pidgio in
  S.straight
    ~route:(route [ s "cat" ] path)
    ~to_pidgin:Encoder.string
    (fun [] path _req -> Eff.cat path)
;;

let write_file =
  let open Pidgio in
  S.notify
    ~route:(route [ s "write"; s "file" ] with_content)
    (fun [] (path, content) _req ->
       let open Eff in
       let+ _ = write_file path content in
       ())
;;

let delete_file =
  let open Pidgio in
  S.notify
    ~route:(route [ s "delete"; s "file" ] path)
    (fun [] path _req ->
       let open Eff in
       let+ _ = delete_file path in
       ())
;;

let fs =
  let open Virtfs in
  Tree.make
    ~scope:Path.root
    Tree.Simple.
      [ dir
          ~name:"a"
          [ dir ~name:"a1" []
          ; dir ~name:"a2" []
          ; dir ~name:"a3" [ file ~name:"foo.txt" "Hello World" ]
          ]
      ; dir
          ~name:"b"
          [ dir ~name:"b1" []; dir ~name:"b2" []; dir ~name:"b3" [] ]
      ; dir
          ~name:"c"
          [ dir ~name:"c1" []; dir ~name:"c2" []; dir ~name:"c3" [] ]
      ; dir
          ~name:"d"
          [ dir
              ~name:"e"
              [ dir ~name:"e1" []; dir ~name:"e2" []; dir ~name:"e3" [] ]
          ]
      ]
;;

let () =
  let handler = Eff.handler fs in
  Server.run ~handler [ ls; cat; write_file; delete_file ]
;;
