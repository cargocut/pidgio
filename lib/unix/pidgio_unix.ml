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
  type input = In_channel.t
  type output = Out_channel.t

  let read_line = In_channel.input_line
  let read_exactly = In_channel.really_input_string
  let write = Out_channel.output_string
  let flush = Out_channel.flush
end

module Make (Json : Pidgio.Sigs.JSON_DEVICE) = struct
  include Pidgio.Server (Monad) (Req) (Json)

  let get_input () =
    let in_channel = Stdlib.stdin in
    let () = set_binary_mode_in in_channel true in
    in_channel
  ;;

  let get_output () =
    let real = Unix.dup Unix.stdout in
    let () = Unix.dup2 Unix.stderr Unix.stdout in
    let out_channel = Unix.out_channel_of_descr real in
    let () = set_binary_mode_out out_channel true in
    out_channel
  ;;

  let run ~handler services =
    let () = if Sys.unix then Sys.set_signal Sys.sigpipe Sys.Signal_ignore in
    let out_channel = get_output ()
    and in_channel = get_input () in
    match run in_channel out_channel ~handler services with
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
