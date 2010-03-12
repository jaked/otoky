open Tokyo_common

type 'a t = {
  type_desc : 'a Type_desc.t;
  marshall : 'a -> Cstr.t;
  unmarshall : Cstr.t -> 'a;
  compare : 'a -> 'a -> int; (* only needed for BDB *)
}

val make :
  type_desc : 'a Type_desc.t ->
  marshall : ('a -> Cstr.t) ->
  unmarshall : (Cstr.t -> 'a) ->
  compare : ('a -> 'a -> int) ->
  'a t

val type_desc_hash : 'a t -> string
