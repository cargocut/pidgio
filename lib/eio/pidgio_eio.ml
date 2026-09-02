(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

module Monad = struct
  type 'a t = 'a

  let return x = x
  let map f = f
  let apply f = f
  let bind x f = f x
end

module Req = struct
  type 'a t = 'a
  type input = Eio.Buf_read.t
  type output = Eio.Buf_write.t

  let read_line r =
    try Some (Eio.Buf_read.line r) with
    | End_of_file -> None
  ;;

  let read_exactly r n =
    try Some (Eio.Buf_read.take n r) with
    | End_of_file -> None
    | Eio.Buf_read.Buffer_limit_exceeded -> None
  ;;

  let write w s = Eio.Buf_write.string w s
  let flush w = Eio.Buf_write.flush w
end

module Make (Json : Pidgio.Sigs.JSON_DEVICE) = struct
  include Pidgio.Server (Monad) (Req) (Json)

  let get_input env =
    Eio.Buf_read.of_flow ~max_size:(64 * 1024 * 1024) (Eio.Stdenv.stdin env)
  ;;

  let get_output sw =
    let real = Unix.dup Unix.stdout in
    let () = Unix.dup2 Unix.stderr Unix.stdout in
    (Eio_unix.Net.import_socket_stream ~sw ~close_unix:true real
      :> Eio.Flow.sink_ty Eio.Resource.t)
  ;;

  let run ~handler services =
    let () = if Sys.unix then Sys.set_signal Sys.sigpipe Sys.Signal_ignore in
    match
      Eio_main.run (fun env ->
        Eio.Switch.run (fun sw ->
          let in_channel = get_input env
          and sink = get_output sw in
          Eio.Buf_write.with_flow sink (fun out_channel ->
            run in_channel out_channel ~handler:(handler env) services)))
    with
    (* KLUDGE: We probably want to improve that :) *)
    | 1 ->
      (* It is a success in fact. *)
      exit 0
    | 2 ->
      let () = prerr_endline "Frame error" in
      exit 2
    | n -> exit n
  ;;
end
