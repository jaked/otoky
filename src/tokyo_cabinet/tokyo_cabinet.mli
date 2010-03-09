open Tokyo_common

val version : unit -> string

type error =
    | Ethread
    | Einvalid
    | Enofile
    | Enoperm
    | Emeta
    | Erhead
    | Eopen
    | Eclose
    | Etrunc
    | Esync
    | Estat
    | Eseek
    | Eread
    | Ewrite
    | Emmap
    | Elock
    | Eunlink
    | Erename
    | Emkdir
    | Ermdir
    | Ekeep
    | Enorec
    | Emisc

exception Error of error * string * string

type omode = Oreader | Owriter | Ocreat | Otrunc | Onolck | Olcknb | Otsync

type opt = Tlarge | Tdeflate | Tbzip | Ttcbs

module ADB :
sig
  type t

  module type Sig =
  sig
    type cstr_t
    type tclist_t

    val new_ : unit -> t

    val adddouble : t -> cstr_t -> float -> float
    val addint : t -> cstr_t -> int -> int
    val close : t -> unit
    val copy : t -> string -> unit
    val fwmkeys : t -> ?max:int -> cstr_t -> tclist_t
    val get : t -> cstr_t -> cstr_t
    val iterinit : t -> unit
    val iternext : t -> cstr_t
    val misc : t -> string -> tclist_t -> tclist_t
    val open_ : t -> string -> unit
    val optimize : t -> ?params:string -> unit -> unit
    val out : t -> cstr_t -> unit
    val path : t -> string
    val put : t -> cstr_t -> cstr_t -> unit
    val putcat : t -> cstr_t -> cstr_t -> unit
    val putkeep : t -> cstr_t -> cstr_t -> unit
    val rnum : t -> int64
    val size : t -> int64
    val sync : t -> unit
    val tranabort : t -> unit
    val tranbegin : t -> unit
    val trancommit : t -> unit
    val vanish : t -> unit
    val vsiz : t -> cstr_t -> int
  end

  include Sig with type cstr_t = string and type tclist_t = string list

  module Fun (Cs : Cstr_t) (Tcl : Tclist_t) : Sig with type cstr_t = Cs.t and type tclist_t = Tcl.t
end

module BDB :
sig
  type cmpfunc =
      | Cmp_lexical | Cmp_decimal | Cmp_int32 | Cmp_int64
      | Cmp_custom of (string -> string -> int) | Cmp_custom_cstr of (string -> int -> string -> int -> int)

  type t

  module type Sig =
  sig
    type cstr_t
    type tclist_t

    val new_ : unit -> t

    val adddouble : t -> cstr_t -> float -> float
    val addint : t -> cstr_t -> int -> int
    val close : t -> unit
    val copy : t -> string -> unit
    val fsiz : t -> int64
    val fwmkeys : t -> ?max:int -> cstr_t -> tclist_t
    val get : t -> cstr_t -> cstr_t
    val getlist : t -> cstr_t -> tclist_t
    val open_ : t -> ?omode:omode list -> string -> unit
    val optimize : t -> ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
    val out : t -> cstr_t -> unit
    val outlist : t -> cstr_t -> unit
    val path : t -> string
    val put : t -> cstr_t -> cstr_t -> unit
    val putcat : t -> cstr_t -> cstr_t -> unit
    val putdup : t -> cstr_t -> cstr_t -> unit
    val putkeep : t -> cstr_t -> cstr_t -> unit
    val putlist : t -> cstr_t -> tclist_t -> unit
    val range : t -> ?bkey:cstr_t -> ?binc:bool -> ?ekey:cstr_t -> ?einc:bool -> ?max:int -> unit -> tclist_t
    val rnum : t -> int64
    val setcache : t -> ?lcnum:int32 -> ?ncnum:int32 -> unit -> unit
    val setcmpfunc : t -> cmpfunc -> unit
    val setdfunit : t -> int32 -> unit
    val setxmsiz : t -> int64 -> unit
    val sync : t -> unit
    val tranabort : t -> unit
    val tranbegin : t -> unit
    val trancommit : t -> unit
    val tune : t -> ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
    val vanish : t -> unit
    val vnum : t -> cstr_t -> int
    val vsiz : t -> cstr_t -> int
  end

  include Sig with type cstr_t = string and type tclist_t = string list

  module Fun (Cs : Cstr_t) (Tcl : Tclist_t) : Sig with type cstr_t = Cs.t and type tclist_t = Tcl.t
end

module BDBCUR :
sig
  type cpmode = Cp_current | Cp_before | Cp_after

  type t

  module type Sig =
  sig
    type cstr_t

    val new_ : BDB.t -> t

    val first : t -> unit
    val jump : t -> cstr_t -> unit
    val key : t -> cstr_t
    val last : t -> unit
    val next : t -> unit
    val out : t -> unit
    val prev : t -> unit
    val put : t -> ?cpmode:cpmode -> cstr_t -> unit
    val val_ : t -> cstr_t
  end

  include Sig with type cstr_t = string

  module Fun (Cs : Cstr_t) : Sig with type cstr_t = Cs.t
end

module FDB :
sig
  val id_min : int64
  val id_prev : int64
  val id_max : int64
  val id_next : int64

  type t

  module type Sig =
  sig
    type cstr_t
    type tclist_t

    val new_ : unit -> t

    val adddouble : t -> int64 -> float -> float
    val addint : t -> int64 -> int -> int
    val close : t -> unit
    val copy : t -> string -> unit
    val fsiz : t -> int64
    val get : t -> int64 -> cstr_t
    val iterinit : t -> unit
    val iternext : t -> int64
    val open_ : t -> ?omode:omode list -> string -> unit
    val optimize : t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
    val out : t -> int64 -> unit
    val path : t -> string
    val put : t -> int64 -> cstr_t -> unit
    val putcat : t -> int64 -> cstr_t -> unit
    val putkeep : t -> int64 -> cstr_t -> unit
    val range : t -> ?max:int -> string -> tclist_t
    val rnum : t -> int64
    val sync : t -> unit
    val tranabort : t -> unit
    val tranbegin : t -> unit
    val trancommit : t -> unit
    val tune : t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
    val vanish : t -> unit
    val vsiz : t -> int64 -> int

    val width : t -> int32
  end

  include Sig with type cstr_t = string and type tclist_t = string list

  module Fun (Cs : Cstr_t) (Tcl : Tclist_t) : Sig with type cstr_t = Cs.t and type tclist_t = Tcl.t
end

module HDB :
sig
  type t

  module type Sig =
  sig
    type cstr_t
    type tclist_t

    val new_ : unit -> t

    val adddouble : t -> cstr_t -> float -> float
    val addint : t -> cstr_t -> int -> int
    val close : t -> unit
    val copy : t -> string -> unit
    val fsiz : t -> int64
    val fwmkeys : t -> ?max:int -> cstr_t -> tclist_t
    val get : t -> cstr_t -> cstr_t
    val iterinit : t -> unit
    val iternext : t -> cstr_t
    val open_ : t -> ?omode:omode list -> string -> unit
    val optimize : t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
    val out : t -> cstr_t -> unit
    val path : t -> string
    val put : t -> cstr_t -> cstr_t -> unit
    val putasync : t -> cstr_t -> cstr_t -> unit
    val putcat : t -> cstr_t -> cstr_t -> unit
    val putkeep : t -> cstr_t -> cstr_t -> unit
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
    val vsiz : t -> cstr_t -> int
  end

  include Sig with type cstr_t = string and type tclist_t = string list

  module Fun (Cs : Cstr_t) (Tcl : Tclist_t) : Sig with type cstr_t = Cs.t and type tclist_t = Tcl.t
end

module TDB :
sig
  type itype = It_lexical | It_decimal | It_token | It_qgram | It_opt | It_void

  type t

  module type Sig =
  sig
    type cstr_t
    type tclist_t
    type tcmap_t

    val new_ : unit -> t

    val adddouble : t -> cstr_t -> float -> float
    val addint : t -> cstr_t -> int -> int
    val close : t -> unit
    val copy : t -> string -> unit
    val fsiz : t -> int64
    val fwmkeys : t -> ?max:int -> cstr_t -> tclist_t
    val genuid : t -> int64
    val get : t -> cstr_t -> tcmap_t
    val iterinit : t -> unit
    val iternext : t -> cstr_t
    val open_ : t -> ?omode:omode list -> string -> unit
    val optimize : t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
    val out : t -> cstr_t -> unit
    val path : t -> string
    val put : t -> cstr_t -> tcmap_t -> unit
    val putcat : t -> cstr_t -> tcmap_t -> unit
    val putkeep : t -> cstr_t -> tcmap_t -> unit
    val rnum : t -> int64
    val setcache : t -> ?rcnum:int32 -> ?lcnum:int32 -> ?ncnum:int32 -> unit -> unit
    val setdfunit : t -> int32 -> unit
    val setindex : t -> string -> ?keep:bool -> itype -> unit
    val setxmsiz : t -> int64 -> unit
    val sync : t -> unit
    val tranabort : t -> unit
    val tranbegin : t -> unit
    val trancommit : t -> unit
    val tune : t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
    val vanish : t -> unit
    val vsiz : t -> cstr_t -> int
  end

  include Sig with type cstr_t = string and type tclist_t = string list and type tcmap_t = (string * string) list

  module Fun (Cs : Cstr_t) (Tcl : Tclist_t) (Tcm : Tcmap_t) :
    Sig with type cstr_t = Cs.t and type tclist_t = Tcl.t and type tcmap_t = Tcm.t
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

  type kopt = Kw_mutab | Kw_muctrl | Kw_mubrct | Kw_noover | Kw_pulead

  type t

  module type Sig =
  sig
    type tclist_t
    type tcmap_t

    val new_ : TDB.t -> t
    val metasearch : ?setop:msetop -> t list -> tclist_t

    val addcond : t -> string -> ?negate:bool -> ?noidx:bool -> qcond -> string -> unit
    val hint : t -> string
    val kwic : t -> ?name:string -> ?width:int -> ?opts:kopt list -> tcmap_t -> tclist_t
    val proc : t -> (string -> tcmap_t ref -> qpost list) -> unit
    val search : t -> tclist_t
    val searchout : t -> unit
    val setlimit : t -> ?max:int -> ?skip:int -> unit -> unit
    val setorder : t -> ?qord:qord -> string -> unit
  end

  include Sig with type tclist_t = string list and type tcmap_t = (string * string) list

  module Fun (Tcl : Tclist_t) (Tcm : Tcmap_t) : Sig with type tclist_t = Tcl.t and type tcmap_t = Tcm.t
end
