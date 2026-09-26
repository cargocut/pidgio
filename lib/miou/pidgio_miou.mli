module Make (_ : Pidgio.Sigs.JSON_DEVICE) : sig
  include Pidgio.Sigs.SERVER with type 'a t = 'a

  (** [run ~handler ~from ~into services] reads JSON-RPC messages from
      the [from] source, dispatches them to the given [services] under
      [handler], and writes the framed responses into the [into] sink. It
      returns the value produced by the [into] sink once the [from]
      source is exhausted.

      The [from] source is expected to produce the raw bytes of the
      protocol (["Content-Length"] framed messages, split into arbitrary
      chunks) and the [into] sink receives the framed responses, ready to
      be transmitted. *)
  val run
    :  handler:'handler
    -> from:string Flux.source
    -> into:(string, 'r) Flux.sink
    -> 'handler service list
    -> 'r
end
