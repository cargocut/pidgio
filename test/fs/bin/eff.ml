(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

include Server.Eff

class type handler = object
  method ls : Virtfs.Path.t -> string list
  method cat : Virtfs.Path.t -> string
  method exists : Virtfs.Path.t -> bool
  method is_dir : Virtfs.Path.t -> bool
  method is_file : Virtfs.Path.t -> bool
  method write_file : Virtfs.Path.t -> string -> unit
  method delete : Virtfs.Path.t -> unit
end

let ls path = perform (fun (h : #handler) -> h#ls path)
let cat path = perform (fun (h : #handler) -> h#cat path)
let exists path = perform (fun (h : #handler) -> h#exists path)
let is_dir path = perform (fun (h : #handler) -> h#is_dir path)
let is_file path = perform (fun (h : #handler) -> h#is_file path)

let write_file path content =
  let* is_file = is_file path in
  if not is_file
  then
    let+ _ = perform (fun (h : #handler) -> h#write_file path content) in
    Ok ()
  else return @@ Error ()
;;

let delete_file path =
  let* exists = exists path in
  if exists
  then
    let+ _ = perform (fun (h : #handler) -> h#delete path) in
    Ok ()
  else return @@ Error ()
;;

let handler tree =
  object (_ : handler)
    val mutable tree : Virtfs.Tree.Simple.t = tree
    method ls path = Virtfs.Tree.ls ~scope:path tree
    method cat path = Virtfs.Tree.cat ~to_string:Fun.id tree path
    method is_dir path = Virtfs.Tree.Simple.is_directory ~path tree
    method is_file path = Virtfs.Tree.Simple.is_file ~path tree
    method exists path = Virtfs.Tree.Simple.file_exists ~path tree

    method write_file path content =
      let new_tree =
        Virtfs.Tree.Simple.write_file ~overwrite:false ~path content tree
      in
      tree <- new_tree

    method delete path =
      let new_tree = Virtfs.Tree.Simple.rm ~recursive:true ~path tree in
      tree <- new_tree
  end
;;
