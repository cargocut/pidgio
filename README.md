> [!WARNING]  
> This project is still **highly experimental**, but we would be
> delighted to receive feedback (but please be careful with
> production).

# pidgio

> **Pidgio** is a very small
> [JSONRPC](https://www.jsonrpc.org/specification) library for
> defining servers that uses
> [Pidgin](https://github.com/cargocut/pidgin) to encode and decode
> JSON, it uses [Highway](https://github.com/cargocut/highway) for
> describing route's path and
> [Primavera](https://github.com/cargocut/primavera) for abstracting
> over dependencies. It writes to `stdout` and reads from `stdin`. It
> was designed primarily to be called by another program (such as
> Emacs).

Every JSONRPC entry-point is parametrized by a Highway `path` (instead
of just a method) and the handler of an entrypoint use
[Primavera](https://github.com/cargocut/primavera) for abstracting
over dependencies/effects.

## Example

Our goal is to have a generic and portable implementation; therefore,
the library makes no assumptions whatsoever about how to handle JSON
and provides an abstraction layer on top of it. `pidgio-yojson` is a
direct implementation based on the
[Yojson.Basic](https://ocaml.org/p/yojson/3.0.0/doc/yojson/Yojson/Basic/index.html)
representation. We will use it for this example.

For the same reason, the library does not handle I/O; instead, two
libraries are provided: `pidgio-unix` (the basic version, which is
based on the Unix module) and `pidgio-eio` (which is based on
Eio). For this example, we will use Unix.

### Building the Server Module

First, we're going to get a module on `Unix` and `Yojson` (using
`pidgio-unix` and `pidgio-yojson):

```ocaml
module Server = Pidgio_unix.Make (Pidgio_yojson)
```

The server module is compact and exposes the API that we will
primarily use. You can view its API in the `lib/sigs.mli` file, which
exposes the complete API. Essentially, there are several things to
note:

- `Server.Eff` which is a Primavera module for abstracting
  effects/dependencies
- What is needed to describe routes (including their paths and
  parameters)
- What is nedded to describe services
- Everything we need to run our server

The logic behind route declaration and routing is described in general
terms in the [Highway](https://github.com/cargocut/highway) project.

### Building our first service

We're going to create two services. The first one responds with `pong`
when you send it `ping`.

```ocaml
let ping =
  let open Server in
  straight
    ~to_pidgin:Pidgin.Repr.string
    (route [ s "ping" ] ignore_param)
    (fun [] () _request -> return "pong")
```

This first example already gives us a lot of clues. First, a route
takes 3 required arguments:

- `to_pidgin`: which allows you to serialize the result into a
  [Pidgin](https://github.com/cargocut/pidgin) expression so you don't
  have to worry about JSON. Here, since our response is a simple
  string, we don't need to go through a lot of steps. (We relay a lot
  on `Pidgin` for describing things, this is why the library is called
  `pidgio`)
  
- `route` the server route which is a `path` + `prism`. A path, a way
  to extract information from a JSON-RPC entry point method, and a
  *Pidgin prism* that describes the entry point's parameters. (A Prism
  includes a `conv` and a `check`, which also allow you to generate
  requests from a route)
  
- `handler`: the service controller. It performs the actual action of
  the service. The form of the function is as follow: `fun
  list_of_path_fragment param_value request -> ...` and returns a
  value wrapped from the module `Eff`.
  
There are other parameters, such as `precondition` and
`postcondition`, but they follow the same conventions as those
described in Highway. It is also possible to use `failable`, which
returns a value of type `(('a, 'b) result, 'handler) eff` and takes an
additional argument, `to_error`, which must convert the error value
into a JSONRPC error so that the focus remains solely on the happy
path. And `notify`, a service that has no request ID and does not
return a result. Notifications can share the same path as a service
(if it appears later in the list) because requests with an ID ignore
notifications in the routing phase.

If we specify the `ping` type as `'_weak39 Server.service'`, it's
essentially because a service's type parameter is a handler that will
be unified with the other services. Without further ado, let's create
a slightly more complicated service.

### A more complicated service

Now that we've looked at a very simple service that doesn't involve
any effects, we can build an `echo` service that will take the following JSON: 

```json
{
  "message": "A string for the message",
  "loudly": true
}
```

Where `message` is obviously the message that we want to echo, and
`loudly` is an optional boolean, if it is set to `true`, the response
will be uppercased.

First, let's define our parameter:

```ocaml
type param =
  { message : string (* The message to echo *)
  ; loudly : bool (* If the flag is set to true, the echo is UPPERCASED *)
  }
```

We can lift it as a parameter using `Server.param` and using `Pidgin`
API:

```ocaml
let echo_param =
  let conv { message; loudly } =
    let open Pidgin.Repr in
    record [ "message", string message; "loudly", bool loudly ]
  and check =
    let open Pidgin.Check in
    record (fun fields ->
      let+ message = req fields "message" string
      and+ loudly = opt fields "loudly" bool in
      { message; loudly = Option.value ~default:false loudly })
  in
  Server.param ~conv ~check
```

Now, we will define our `response`: 

```ocaml
type response =
  { message : string
  ; loudly : bool
  ; time : float (* this field is here just to use effects ... *)
  }
```

Let's write a `to_pidgin` function for our response: 

```ocaml
let response_to_pidgin { message; loudly; time } =
  let open Pidgin.Repr in
  record
    [ "message", string message
    ; "loudly", bool loudly
    ; "time", float time ]
```

Now, let's define our service:

```ocaml
let echo =
  let open Server in
  straight
    ~to_pidgin:response_to_pidgin
    (route [ s "echo" ] echo_param)
    (fun [] { message; loudly } _req ->
       let+ time = Eff.perform (fun h -> h#get_time) in
       let message =
         if loudly then String.uppercase_ascii message else message
       in
       { message; loudly; time })
```

Now, if we inspect the type of `echo` : `(< get_time : float; .. > as
'_weak6) Server.service` we keep the variable weakly generalized but
we see that we need, at least, to handle the `get_time` method (thanks
to Primavera).

### Running the server 

Now we can start our server by providing it with a dependency
manager—which is an object (allowing handlers to be composed modularly
through inheritance) and a list of services.

```ocaml
let () =
  let handler =
    object
      method get_time = Unix.time ()
    end
  in
  Server.run ~handler [ ping; echo ]
```

_And voila_ !

## Trivia

Pidgio is a broadly generic implementation of the experiment described
in [Kohai](https://github.com/xvw/kohai) for **controlling software
from within Emacs** (and potentially other editors). Its goal is not
to be very strict in how it handles JSON-RPC, but to make it easy to
take advantage of a code editor’s toolkit to get a user interface
“_for free_” when building software. The general idea is described in
the [following
presentation](https://docs.google.com/presentation/d/e/2PACX-1vSarzOfan3JksrwgEZ2xlEBcJfafD_VoGsad3J37I8HvynUGUJETLxHH6RVl6IP_2na4UxKMscZZJLo/pub?start=false&loop=false&delayms=60000#slide=id.p).
