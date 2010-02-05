type omode
type opt
type cpmode

module type Type =
sig
  type t
  (* XXX with bin-prot, type_hash *)
end

module BDB (K : Type) (V : Type) :
sig
  type t

  val open_ : ?omode:omode list -> ?cmpfunc:(K.t -> K.t -> int) -> string -> t

 (* XXX functorize V.t lists? *)

  val close : t -> unit
  val copy : t -> string -> unit
  val fsiz : t -> int64
  val get : t -> K.t -> V.t
  val getlist : t -> K.t -> V.t list
  val optimize : t -> ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
  val out : t -> K.t -> unit
  val outlist : t -> K.t -> unit
  val path : t -> string
  val put : t -> K.t -> V.t -> unit
  val putdup : t -> K.t -> V.t -> unit
  val putkeep : t -> K.t -> V.t -> unit
  val putlist : t -> K.t -> V.t list -> unit
  val range : t -> ?bkey:K.t -> ?binc:bool -> ?ekey:K.t -> ?einc:bool -> ?max:int -> unit -> V.t list
  val rnum : t -> int64
  val setcache : t -> ?lcnum:int32 -> ?ncnum:int32 -> unit -> unit
  val setdfunit : t -> int32 -> unit
  val setxmsiz : t -> int64 -> unit
  val sync : t -> unit
  val tranabort : t -> unit
  val tranbegin : t -> unit
  val trancommit : t -> unit
  val tune : t -> ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
  val vanish : t -> unit
  val vnum : t -> K.t -> int
  val vsiz : t -> K.t -> int

  module CUR :
  sig
    type c

    val new_ : t -> c

    val first : c -> unit
    val jump : c -> K.t -> unit
    val key : c -> K.t
    val last : c -> unit
    val next : c -> unit
    val out : c -> unit
    val prev : c -> unit
    val put : c -> ?cpmode:cpmode -> V.t -> unit
    val val_ : c -> V.t
  end
end

module FDB (V : Type) :
sig
  type t

  val open_ : ?omode:omode list -> string -> t

  val close : t -> unit
  val copy : t -> string -> unit
  val fsiz : t -> int64
  val get : t -> int64 -> V.t
  val iterinit : t -> unit
  val iternext : t -> int64
  val optimize : t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
  val out : t -> int64 -> unit
  val path : t -> string
  val put : t -> int64 -> V.t -> unit
  val putkeep : t -> int64 -> V.t -> unit
  val range : t -> ?max:int -> string -> string list (* XXX t*)
  val rnum : t -> int64
  val sync : t -> unit
  val tranabort : t -> unit
  val tranbegin : t -> unit
  val trancommit : t -> unit
  val tune : t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
  val vanish : t -> unit
  val vsiz : t -> int64 -> int
end

module HDB (K : Type) (V : Type) :
sig
  type t

  val open_ : ?omode:omode list -> string -> t

  val close : t -> unit
  val copy : t -> string -> unit
  val fsiz : t -> int64
  val get : t -> K.t -> V.t
  val iterinit : t -> unit
  val iternext : t -> K.t
  val optimize : t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
  val out : t -> K.t -> unit
  val path : t -> string
  val put : t -> K.t -> V.t -> unit
  val putasync : t -> K.t -> V.t -> unit
  val putkeep : t -> K.t -> V.t -> unit
  val rnum : t -> int64
  val setcache : t -> int32 -> unit
  val setdfunit : t -> int32 -> unit
  val setxmsiz : t -> int64 -> unit
  val sync : t -> unit
  val tranabort : t -> unit
  val tranbegin : t -> unit
  val trancommit : t -> unit
  val tune : t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
  val vanish : t -> unit
  val vsiz : t -> K.t -> int
end
