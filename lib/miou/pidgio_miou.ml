module Monad = struct
  type 'a t = 'a

  let return x = x
  let map f = f
  let apply f = f
  let bind x f = f x
end

module Reader = struct
  type t =
    { mutable src : string Flux.source
    ; mutable buf : string
    ; mutable off : int
    ; mutable eof : bool
    }

  let of_source src = { src; buf = ""; off = 0; eof = false }

  let fill t =
    if t.eof
    then false
    else (
      (match Flux.Source.next t.src with
       | None -> t.eof <- true
       | Some (chunk, src) ->
         t.src <- src;
         let rest = String.sub t.buf t.off (String.length t.buf - t.off) in
         t.buf <- rest ^ chunk;
         t.off <- 0);
      not t.eof)
  ;;

  let strip_cr line =
    let n = String.length line in
    if n > 0 && line.[n - 1] = '\r' then String.sub line 0 (n - 1) else line
  ;;

  let rec read_line t =
    match String.index_from_opt t.buf t.off '\n' with
    | Some i ->
      let line = String.sub t.buf t.off (i - t.off) in
      t.off <- i + 1;
      Some (strip_cr line)
    | None ->
      if fill t
      then read_line t
      else (
        let n = String.length t.buf - t.off in
        if n = 0
        then None
        else (
          let line = String.sub t.buf t.off n in
          t.off <- String.length t.buf;
          Some (strip_cr line)))
  ;;

  let rec read_exactly t n =
    let available = String.length t.buf - t.off in
    if available >= n
    then (
      let s = String.sub t.buf t.off n in
      t.off <- t.off + n;
      Some s)
    else if fill t
    then read_exactly t n
    else None
  ;;
end

module Writer = struct
  type t =
    { push : string -> unit
    ; flush : unit -> unit
    }
end

module Req = struct
  type 'a t = 'a
  type input = Reader.t
  type output = Writer.t

  let read_line = Reader.read_line
  let read_exactly = Reader.read_exactly
  let write (out : output) s = out.Writer.push s
  let flush (out : output) = out.Writer.flush ()
end

module Make (Json : Pidgio.Sigs.JSON_DEVICE) = struct
  include Pidgio.Server (Monad) (Req) (Json)

  let run ~handler ~from:src ~into services =
    (* NOTE(dinosaure): unroll our sink. *)
    let (Flux.Sink dst) = into in
    let state = ref (dst.init ()) in
    let output =
      { Writer.push =
          (fun s -> if not (dst.full !state) then state := dst.push !state s)
      ; Writer.flush = (fun () -> ())
      }
    in
    let input = Reader.of_source src in
    let _code = run input output ~handler services in
    dst.stop !state
  ;;
end
