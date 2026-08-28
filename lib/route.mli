(* Copyright (c) 2026, Cargocut and the Pidgio developers.
   All rights reserved.

   SPDX-License-Identifier: BSD-3-Clause *)

(** Describe a route. In the JSONRPC, it is the field [method]. *)

(** {1 Types} *)

(** Describe a route path. ['args] is the heterogeonous list of holes
    and ['params] is the [params] field of a JSONRPC request. *)
type ('args, 'params) t

(** {1 Building routes} *)

(** [make path params_validator] build a route. *)
val make
  :  ('args, Highway.Void.t) Highway.path
  -> 'params Pidgin.Check.t
  -> ('args, 'params) t

(** {1 Routes components} *)

(** [extract_path route req] try to extract path argument from a route
    with a request. *)
val extract_path : ('args, _) t -> _ Request.t -> 'args Highway.args option

(**[extract_params route req] try to extract param from a route with a
   request. *)
val extract_params
  :  (_, 'params) t
  -> (Pidgin.Repr.t Request.t, 'params) Pidgin.Check.fn
