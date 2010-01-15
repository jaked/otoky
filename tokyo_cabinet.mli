val version : unit -> string

type omode = Oreader | Owriter | Ocreat | Otrunc | Onolck | Olcknb | Otsync

type opt = Tlarge | Tdeflate | Tbzip | Ttcbs

module ADB :
sig
  type t

  val new_ : unit -> t

  val adddouble : t -> string -> float -> float
  val addint : t -> string -> int -> int
  val close : t -> unit
  val copy : t -> string -> unit
  val fwmkeys : t -> ?max:int -> string -> string list
  val get : t -> string -> string
  val iterinit : t -> unit
  val iternext : t -> string
  val misc : t -> string -> string list -> string list
  val open_ : t -> string -> unit
  val optimize : t -> string -> unit
  val out : t -> string -> unit
  val path : t -> string
  val put : t -> string -> string -> unit
  val putcat : t -> string -> string -> unit
  val putkeep : t -> string -> string -> unit
  val rnum : t -> int64
  val size : t -> int64
  val sync : t -> unit
  val tranabort : t -> unit
  val tranbegin : t -> unit
  val trancommit : t -> unit
  val vanish : t -> unit
  val vsiz : t -> string -> int
end

module BDB :
sig
  type cmpfunc = Cmp_lexical | Cmp_decimal | Cmp_int32 | Cmp_int64 | Cmp_custom of (string -> string -> int)

  type t

  val new_ : unit -> t

  val adddouble : t -> string -> float -> float
  val addint : t -> string -> int -> int
  val close : t -> unit
  val copy : t -> string -> unit
  val fsiz : t -> int64
  val fwmkeys : t -> ?max:int -> string -> string list
  val get : t -> string -> string
  val getlist : t -> string -> string list
  val open_ : t -> ?mode:omode list -> string -> unit
  val optimize : t -> ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
  val out : t -> string -> unit
  val outlist : t -> string -> unit
  val path : t -> string
  val put : t -> string -> string -> unit
  val putcat : t -> string -> string -> unit
  val putdup : t -> string -> string -> unit
  val putkeep : t -> string -> string -> unit
  val putlist : t -> string -> string list -> unit
  val range : t -> ?bkey:string -> ?binc:bool -> ?ekey:string -> ?einc:bool -> ?max:int -> string list
  val rnum : t -> int64
  val setcache : t -> ?lcnum:int -> ?ncnum:int -> unit -> unit
  val setcmpfunc : t -> cmpfunc -> unit
  val setdfunit : t -> int32 -> unit
  val setxmsiz : t -> int64 -> unit
  val sync : t -> unit
  val tranabort : t -> unit
  val tranbegin : t -> unit
  val trancommit : t -> unit
  val tune : t -> ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
  val vanish : t -> unit
  val vnum : t -> string -> int
  val vsiz : t -> string -> int
end

module BDBCUR :
sig
  type cpmode = Cp_current | Cp_before | Cp_after

  type t

  val new_ : BDB.t -> t

  val first : t -> unit
  val jump : t -> string -> unit
  val key : t -> string
  val last : t -> unit
  val next : t -> unit
  val out : t -> unit
  val prev : t -> unit
  val put : t -> string -> cpmode -> unit
  val val_ : t -> string
end

module FDB :
sig
  type id = Id_min | Id_max | Id_prev | Id_next | Id of int64

  type t

  val new_ : unit -> t

  val adddouble : t -> string -> float -> float
  val addint : t -> string -> int -> int
  val close : t -> unit
  val copy : t -> string -> unit
  val fsiz : t -> int64
  val get : t -> int64 -> string
  val iterinit : t -> unit
  val iternext : t -> int64
  val open_ : t -> ?omode:omode list -> string -> unit
  val optimize : t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
  val out : t -> int64 -> unit
  val path : t -> string
  val put : t -> int64 -> string -> unit
  val putcat : t -> int64 -> string -> unit
  val putkeep : t -> int64 -> string -> unit
  val range : t -> string -> int -> string list
  val rnum : t -> int64
  val sync : t -> unit
  val tranabort : t -> unit
  val tranbegin : t -> unit
  val trancommit : t -> unit
  val tune : t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
  val vanish : t -> unit
  val vsiz : t -> int64 -> int

  val id : id -> int64
end

module HDB :
sig
  type t

  val new_ : unit -> t

  val adddouble : t -> string -> float -> float
  val addint : t -> string -> int -> int
  val close : t -> unit
  val copy : t -> string -> unit
  val fsiz : t -> int64
  val fwmkeys : t -> ?max:int -> string -> string list
  val get : t -> string -> string
  val iterinit : t -> unit
  val iternext : t -> string
  val open_ : t -> ?omode:omode list -> string -> unit
  val optimize : t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
  val out : t -> string -> unit
  val path : t -> string
  val put : t -> string -> string -> unit
  val putasync : t -> string -> string -> unit
  val putcat : t -> string -> string -> unit
  val putkeep : t -> string -> string -> unit
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
  val vsiz : t -> string -> int
end

module TDB :
sig
  type itype = It_lexical | It_decimal | It_token | It_qgram | It_opt | It_void | It_keep

  type t

  val new_ : unit -> t

  val adddouble : t -> string -> float -> float
  val addint : t -> string -> int -> int
  val close : t -> unit
  val copy : t -> string -> unit
  val fsiz : t -> int64
  val fwmkeys : t -> ?max:int -> string -> string list
  val genuid : t -> int64
  val get : t -> string -> (string * string) list
  val iterinit : t -> unit
  val iternext : t -> string
  val open_ : t -> string -> unit
  val optimize : t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
  val out : t -> string -> unit
  val path : t -> string
  val put : t -> string -> (string * string) list -> unit
  val putcat : t -> string -> (string * string) list -> unit
  val putkeep : t -> string -> (string * string) list -> unit
  val rnum : t -> int64
  val setcache : t -> int32 -> unit
  val setdfunit : t -> int32 -> unit
  val setindex : t -> string -> itype -> unit
  val setxmsiz : t -> int64 -> unit
  val sync : t -> unit
  val tranabort : t -> unit
  val tranbegin : t -> unit
  val trancommit : t -> unit
  val tune : t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
  val vanish : t -> unit
  val vsiz : t -> string -> int
end

module TDBQRY :
sig
  type qcond =
      | Qc_streq | Qc_strinc | Qc_strbw | Qc_strew | Qc_strand | Qc_stror | Qc_stroreq | Qc_strrx
      | Qc_numeq | Qc_numgt | Qc_numge | Qc_numlt | Qc_numle | Qc_numbt | Qc_numoreq
      | Qc_ftsph | Qc_ftsand | Qc_ftsor | Qc_ftsex

  type qord = Qo_strasc | Qo_strdesc | Qo_numasc | Qo_numdesc

  type qpost = Qp_put | Qp_out | Qp_stop

  type msetop = Ms_union | Ms_isect | Ms_diff

  type kwic = Kw_mutab | Kw_muctrl | Kw_mubrct | Kw_noover | Kw_pulead

  type t

  val new_ : TDB.t -> t

  val addcond : t -> string -> ?negate:bool -> ?noidx:bool -> qcond -> string -> unit
  val hint : t -> string
  val kwic : t -> (string * string) list -> string -> int -> kwic list -> string list
  val metaseach : t list -> msetop -> string list
  val proc : t -> (string -> (string * string) list -> qpost list) -> unit
  val search : t -> string list
  val searchout : t -> unit
  val setlimit : t -> int -> int -> unit
  val setorder : t -> string -> qord -> unit
end
