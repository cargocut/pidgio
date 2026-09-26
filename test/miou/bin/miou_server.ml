module S = Pidgio_miou.Make (Pidgio_yojson)

let simple_message =
  S.param
    ~check:
      Pidgin.Check.(
        record (fun fields ->
          let+ message = req fields "message" string
          and+ shout = opt fields "shout" bool in
          message, Option.value ~default:false shout))
    ~conv:
      Pidgin.Repr.(
        fun (message, shout) ->
          record [ "message", string message; "shout", bool shout ])
;;

let () =
  Miou_unix.run
  @@ fun () ->
  let open S in
  run
    ~handler:object end
    ~from:(Flux.Source.in_channel ~close:false Stdlib.stdin)
    ~into:(Flux.Sink.out_channel ~close:false Stdlib.stdout)
    [ straight
        ~&[ s "ping" ]
        ~to_pidgin:Pidgin.Repr.string
        (fun [] () _ -> return "pong")
    ; straight
        ([ s "echo" ] & simple_message)
        ~to_pidgin:Pidgin.Repr.string
        (fun [] (message, shout) _req ->
           let message =
             if shout then String.uppercase_ascii message else message
           in
           return message)
    ]
;;
