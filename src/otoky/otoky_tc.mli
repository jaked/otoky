type 'a typ = {
  type_desc : 'a Type_desc.t;
  marshall : 'a -> Tokyo_common.Cstr.t;
  unmarshall : Tokyo_common.Cstr.t -> 'a;
  compare : 'a -> 'a -> int; (* only needed for BDB *)
}

module BDB :
sig
  type ('k, 'v) t

  val open_ : ?omode:Tokyo_cabinet.omode list -> 'k typ -> 'v typ -> string -> ('k, 'v) t

  val close : ('k, 'v) t -> unit
  val copy : ('k, 'v) t -> string -> unit
  val fsiz : ('k, 'v) t -> int64
  val get : ('k, 'v) t -> 'k -> 'v
  val getlist : ('k, 'v) t -> 'k -> 'v list

  val optimize :
    ('k, 'v) t ->
    ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:Tokyo_cabinet.opt list -> unit ->
    unit

  val out : ('k, 'v) t -> 'k -> unit
  val outlist : ('k, 'v) t -> 'k -> unit
  val path : ('k, 'v) t -> string
  val put : ('k, 'v) t -> 'k -> 'v -> unit
  val putdup : ('k, 'v) t -> 'k -> 'v -> unit
  val putkeep : ('k, 'v) t -> 'k -> 'v -> unit
  val putlist : ('k, 'v) t -> 'k -> 'v list -> unit

  val range :
    ('k, 'v) t ->
    ?bkey:'k -> ?binc:bool -> ?ekey:'k -> ?einc:bool -> ?max:int -> unit ->
    'v list

  val rnum : ('k, 'v) t -> int64
  val setcache : ('k, 'v) t -> ?lcnum:int32 -> ?ncnum:int32 -> unit -> unit
  val setdfunit : ('k, 'v) t -> int32 -> unit
  val setxmsiz : ('k, 'v) t -> int64 -> unit
  val sync : ('k, 'v) t -> unit
  val tranabort : ('k, 'v) t -> unit
  val tranbegin : ('k, 'v) t -> unit
  val trancommit : ('k, 'v) t -> unit

  val tune :
    ('k, 'v) t ->
    ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:Tokyo_cabinet.opt list -> unit ->
    unit

  val vanish : ('k, 'v) t -> unit
  val vnum : ('k, 'v) t -> 'k -> int
  val vsiz : ('k, 'v) t -> 'k -> int
end

module BDBCUR :
sig
  type ('k, 'v) t

  val new_ : ('k, 'v) BDB.t -> ('k, 'v) t

  val first : ('k, 'v) t -> unit
  val jump : ('k, 'v) t -> 'k -> unit
  val key : ('k, 'v) t -> 'k
  val last : ('k, 'v) t -> unit
  val next : ('k, 'v) t -> unit
  val out : ('k, 'v) t -> unit
  val prev : ('k, 'v) t -> unit
  val put : ('k, 'v) t -> ?cpmode:Tokyo_cabinet.BDBCUR.cpmode -> 'v -> unit
  val val_ : ('k, 'v) t -> 'v
end

module FDB :
sig
  type 'v t

  val open_ : ?omode:Tokyo_cabinet.omode list -> 'v typ -> string -> 'v t

  val close : 'v t -> unit
  val copy : 'v t -> string -> unit
  val fsiz : 'v t -> int64
  val get : 'v t -> int64 -> 'v
  val iterinit : 'v t -> unit
  val iternext : 'v t -> int64
  val optimize : 'v t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
  val out : 'v t -> int64 -> unit
  val path : 'v t -> string
  val put : 'v t -> int64 -> 'v -> unit
  val putkeep : 'v t -> int64 -> 'v -> unit
  val range : 'v t -> ?max:int -> string -> string list (* XXX t*)
  val rnum : 'v t -> int64
  val sync : 'v t -> unit
  val tranabort : 'v t -> unit
  val tranbegin : 'v t -> unit
  val trancommit : 'v t -> unit
  val tune : 'v t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
  val vanish : 'v t -> unit
  val vsiz : 'v t -> int64 -> int
end

module HDB :
sig
  type ('k, 'v) t

  val open_ : ?omode:Tokyo_cabinet.omode list -> 'k typ -> 'v typ -> string -> ('k, 'v) t

  val close : ('k, 'v) t -> unit
  val copy : ('k, 'v) t -> string -> unit
  val fsiz : ('k, 'v) t -> int64
  val get : ('k, 'v) t -> 'k -> 'v
  val iterinit : ('k, 'v) t -> unit
  val iternext : ('k, 'v) t -> 'k
  val optimize : ('k, 'v) t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:Tokyo_cabinet.opt list -> unit -> unit
  val out : ('k, 'v) t -> 'k -> unit
  val path : ('k, 'v) t -> string
  val put : ('k, 'v) t -> 'k -> 'v -> unit
  val putasync : ('k, 'v) t -> 'k -> 'v -> unit
  val putkeep : ('k, 'v) t -> 'k -> 'v -> unit
  val rnum : ('k, 'v) t -> int64
  val setcache : ('k, 'v) t -> int32 -> unit
  val setdfunit : ('k, 'v) t -> int32 -> unit
  val setxmsiz : ('k, 'v) t -> int64 -> unit
  val sync : ('k, 'v) t -> unit
  val tranabort : ('k, 'v) t -> unit
  val tranbegin : ('k, 'v) t -> unit
  val trancommit : ('k, 'v) t -> unit
  val tune : ('k, 'v) t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:Tokyo_cabinet.opt list -> unit -> unit
  val vanish : ('k, 'v) t -> unit
  val vsiz : ('k, 'v) t -> 'k -> int
end
