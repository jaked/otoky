let version () = failwith "unimplemented"

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

exception Error of error * string

type omode = Oreader | Owriter | Ocreat | Otrunc | Onolck | Olcknb | Otsync

type opt = Tlarge | Tdeflate | Tbzip | Ttcbs

module Tclist =
struct
  type t

end

module Tcmap =
struct
  type t

end

module type Tclist_t =
sig
  type t

  val of_tclist : Tclist.t -> t
  val to_tclist : t -> Tclist.t
end

module type Tcmap_t =
sig
  type t

  val of_tcmap : Tcmap.t -> t
  val to_tcmap : t -> Tcmap.t
end

module Tclist_list =
struct
  type t = string list

  let of_tclist tc = failwith "unimplemented"
  let to_tclist t = failwith "unimplemented"
end

module Tclist_array =
struct
  type t = string array

  let of_tclist tc = failwith "unimplemented"
  let to_tclist t = failwith "unimplemented"
end

module Tclist_tclist =
struct
  type t = Tclist.t

  external of_tclist : Tclist.t -> t = "%identity"
  external to_tclist : t -> Tclist.t = "%identity"
end

module Tcmap_list =
struct
  type t = (string * string) list

  let of_tcmap tc = failwith "unimplemented"
  let to_tcmap t = failwith "unimplemented"
end

module Tcmap_array =
struct
  type t = (string * string) array

  let of_tcmap tc = failwith "unimplemented"
  let to_tcmap t = failwith "unimplemented"
end

module Tcmap_hashtbl =
struct
  type t = (string, string) Hashtbl.t

  let of_tcmap tc = failwith "unimplemented"
  let to_tcmap t = failwith "unimplemented"
end

module Tcmap_tcmap =
struct
  type t = Tcmap.t

  external of_tcmap : Tcmap.t -> t = "%identity"
  external to_tcmap : t -> Tcmap.t = "%identity"
end

module ADB =
struct
  type t

  module type Sig =
  sig
    type tclist_t

    val new_ : unit -> t

    val adddouble : t -> string -> float -> float
    val addint : t -> string -> int -> int
    val close : t -> unit
    val copy : t -> string -> unit
    val fwmkeys : t -> ?max:int -> string -> tclist_t
    val get : t -> string -> string
    val iterinit : t -> unit
    val iternext : t -> string
    val misc : t -> string -> tclist_t -> tclist_t
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

  module Fun (Tcl : Tclist_t) =
  struct
    type tclist_t = Tcl.t

    external new_ : unit -> t = "otoky_adb_new"

    external adddouble : t -> string -> float -> float = "otoky_adb_adddouble"
    external addint : t -> string -> int -> int = "otoky_adb_addint"
    external close : t -> unit = "otoky_adb_close"
    external copy : t -> string -> unit = "otoky_adb_copy"

    external _fwmkeys : t -> ?max:int -> string -> Tclist.t = "otoky_adb_fwmkeys"
    let fwmkeys t ?max prefix = Tcl.of_tclist (_fwmkeys t ?max prefix)

    let get t key = failwith "unimplemented"
    let iterinit t = failwith "unimplemented"
    let iternext t = failwith "unimplemented"
    let misc t name args = failwith "unimplemented"
    let open_ t name = failwith "unimplemented"
    let optimize t params = failwith "unimplemented"
    let out t key = failwith "unimplemented"
    let path t = failwith "unimplemented"
    let put t key value = failwith "unimplemented"
    let putcat t key value = failwith "unimplemented"
    let putkeep t key value = failwith "unimplemented"
    let rnum t = failwith "unimplemented"
    let size t = failwith "unimplemented"
    let sync t = failwith "unimplemented"
    let tranabort t = failwith "unimplemented"
    let tranbegin t = failwith "unimplemented"
    let trancommit t = failwith "unimplemented"
    let vanish t = failwith "unimplemented"
    let vsiz t key = failwith "unimplemented"
  end

  include Fun (Tclist_list)
end

module BDB =
struct
  type cmpfunc = Cmp_lexical | Cmp_decimal | Cmp_int32 | Cmp_int64 | Cmp_custom of (string -> string -> int)

  type t

  module type Sig =
  sig
    type tclist_t

    val new_ : unit -> t

    val adddouble : t -> string -> float -> float
    val addint : t -> string -> int -> int
    val close : t -> unit
    val copy : t -> string -> unit
    val fsiz : t -> int64
    val fwmkeys : t -> ?max:int -> string -> tclist_t
    val get : t -> string -> string
    val getlist : t -> string -> tclist_t
    val open_ : t -> ?mode:omode list -> string -> unit
    val optimize : t -> ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
    val out : t -> string -> unit
    val outlist : t -> string -> unit
    val path : t -> string
    val put : t -> string -> string -> unit
    val putcat : t -> string -> string -> unit
    val putdup : t -> string -> string -> unit
    val putkeep : t -> string -> string -> unit
    val putlist : t -> string -> tclist_t -> unit
    val range : t -> ?bkey:string -> ?binc:bool -> ?ekey:string -> ?einc:bool -> ?max:int -> tclist_t
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

  module Fun (Tcl : Tclist_t) =
  struct
    type tclist_t = Tcl.t

    let new_ () = failwith "unimplemented"
  
    let adddouble t key num = failwith "unimplemented"
    let addint t key num = failwith "unimplemented"
    let close t = failwith "unimplemented"
    let copy t path = failwith "unimplemented"
    let fsiz t = failwith "unimplemented"
    let fwmkeys t ?max prefix = failwith "unimplemented"
    let get t key = failwith "unimplemented"
    let getlist t key = failwith "unimplemented"
    let open_ t ?mode path = failwith "unimplemented"
    let optimize t ?lmemb ?nmemb ?bnum ?apow ?fpow ?opts () = failwith "unimplemented"
    let out t key = failwith "unimplemented"
    let outlist t key = failwith "unimplemented"
    let path t = failwith "unimplemented"
    let put t key value = failwith "unimplemented"
    let putcat t key value = failwith "unimplemented"
    let putdup t key value = failwith "unimplemented"
    let putkeep t key value = failwith "unimplemented"
    let putlist t key value = failwith "unimplemented"
    let range t ?bkey ?binc ?ekey ?einc ?max = failwith "unimplemented"
    let rnum t = failwith "unimplemented"
    let setcache t ?lcnum ?ncnum () = failwith "unimplemented"
    let setcmpfunc t cmp = failwith "unimplemented"
    let setdfunit t dfunit = failwith "unimplemented"
    let setxmsiz t xmsiz = failwith "unimplemented"
    let sync t = failwith "unimplemented"
    let tranabort t = failwith "unimplemented"
    let tranbegin t = failwith "unimplemented"
    let trancommit t = failwith "unimplemented"
    let tune t ?lmemb ?nmemb ?bnum ?apow ?fpow ?opts () = failwith "unimplemented"
    let vanish t = failwith "unimplemented"
    let vnum t key = failwith "unimplemented"
    let vsiz t key = failwith "unimplemented"
  end

  include Fun (Tclist_list)
end

module BDBCUR =
struct
  type cpmode = Cp_current | Cp_before | Cp_after

  type t

  let new_ bdb = failwith "unimplemented"

  let first t = failwith "unimplemented"
  let jump t key = failwith "unimplemented"
  let key t = failwith "unimplemented"
  let last t = failwith "unimplemented"
  let next t = failwith "unimplemented"
  let out t = failwith "unimplemented"
  let prev t = failwith "unimplemented"
  let put t value cpmode = failwith "unimplemented"
  let val_ t = failwith "unimplemented"
end

module FDB =
struct
  let id_min = -1L
  let id_prev = -2L
  let id_max = -3L
  let id_next = -4L

  type t

  module type Sig =
  sig
    type tclist_t

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
    val range : t -> ?max:int -> string -> tclist_t
    val rnum : t -> int64
    val sync : t -> unit
    val tranabort : t -> unit
    val tranbegin : t -> unit
    val trancommit : t -> unit
    val tune : t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
    val vanish : t -> unit
    val vsiz : t -> int64 -> int
  end

  module Fun (Tcl : Tclist_t) =
  struct
    type tclist_t = Tcl.t

    let new_ () = failwith "unimplemented"
  
    let adddouble t key num = failwith "unimplemented"
    let addint t key num = failwith "unimplemented"
    let close t = failwith "unimplemented"
    let copy t path = failwith "unimplemented"
    let fsiz t = failwith "unimplemented"
    let get t key = failwith "unimplemented"
    let iterinit t = failwith "unimplemented"
    let iternext t = failwith "unimplemented"
    let open_ t ?omode path = failwith "unimplemented"
    let optimize t ?width ?limsiz () = failwith "unimplemented"
    let out t key = failwith "unimplemented"
    let path t  = failwith "unimplemented"
    let put t key value = failwith "unimplemented"
    let putcat t key value = failwith "unimplemented"
    let putkeep t key value = failwith "unimplemented"
    let range t ?max interval = failwith "unimplemented"
    let rnum t = failwith "unimplemented"
    let sync t = failwith "unimplemented"
    let tranabort t = failwith "unimplemented"
    let tranbegin t = failwith "unimplemented"
    let trancommit t = failwith "unimplemented"
    let tune t ?width ?limsiz () = failwith "unimplemented"
    let vanish t = failwith "unimplemented"
    let vsiz t key = failwith "unimplemented"
  end

  include Fun (Tclist_list)
end

module HDB =
struct
  type t

  module type Sig =
  sig
    type tclist_t

    val new_ : unit -> t

    val adddouble : t -> string -> float -> float
    val addint : t -> string -> int -> int
    val close : t -> unit
    val copy : t -> string -> unit
    val fsiz : t -> int64
    val fwmkeys : t -> ?max:int -> string -> tclist_t
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

  module Fun (Tcl : Tclist_t) =
  struct
    type tclist_t = Tcl.t

    let new_ () = failwith "unimplemented"
  
    let adddouble t key num = failwith "unimplemented"
    let addint t key num = failwith "unimplemented"
    let close t = failwith "unimplemented"
    let copy t path = failwith "unimplemented"
    let fsiz t = failwith "unimplemented"
    let fwmkeys t ?max prefix = failwith "unimplemented"
    let get t key = failwith "unimplemented"
    let iterinit t = failwith "unimplemented"
    let iternext t = failwith "unimplemented"
    let open_ t ?omode path = failwith "unimplemented"
    let optimize t ?bnum ?apow ?fpow ?opts () = failwith "unimplemented"
    let out t key = failwith "unimplemented"
    let path t = failwith "unimplemented"
    let put t key value = failwith "unimplemented"
    let putasync t key value = failwith "unimplemented"
    let putcat t key value = failwith "unimplemented"
    let putkeep t key value = failwith "unimplemented"
    let rnum t = failwith "unimplemented"
    let setcache t rcnum = failwith "unimplemented"
    let setdfunit t dfunit = failwith "unimplemented"
    let setxmsiz t xmsiz = failwith "unimplemented"
    let sync t = failwith "unimplemented"
    let tranabort t = failwith "unimplemented"
    let tranbegin t = failwith "unimplemented"
    let trancommit t = failwith "unimplemented"
    let tune t ?bnum ?apow ?fpow ?opts () = failwith "unimplemented"
    let vanish t = failwith "unimplemented"
    let vsiz t key = failwith "unimplemented"
  end

  include Fun (Tclist_list)
end

module TDB =
struct
  type itype = It_lexical | It_decimal | It_token | It_qgram | It_opt | It_void | It_keep

  type t

  module type Sig =
  sig
    type tclist_t
    type tcmap_t

    val new_ : unit -> t

    val adddouble : t -> string -> float -> float
    val addint : t -> string -> int -> int
    val close : t -> unit
    val copy : t -> string -> unit
    val fsiz : t -> int64
    val fwmkeys : t -> ?max:int -> string -> tclist_t
    val genuid : t -> int64
    val get : t -> string -> tcmap_t
    val iterinit : t -> unit
    val iternext : t -> string
    val open_ : t -> ?omode:omode list -> string -> unit
    val optimize : t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
    val out : t -> string -> unit
    val path : t -> string
    val put : t -> string -> tcmap_t -> unit
    val putcat : t -> string -> tcmap_t -> unit
    val putkeep : t -> string -> tcmap_t -> unit
    val rnum : t -> int64
    val setcache : t -> ?rcnum:int32 -> ?lcnum:int32 -> ?ncnum:int32 -> unit -> unit
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

  module Fun (Tcl : Tclist_t) (Tcm : Tcmap_t) =
  struct
    type tclist_t = Tcl.t
    type tcmap_t = Tcm.t

    let new_ () = failwith "unimplemented"
  
    let adddouble t pkey num = failwith "unimplemented"
    let addint t pkey num = failwith "unimplemented"
    let close t = failwith "unimplemented"
    let copy t path = failwith "unimplemented"
    let fsiz t = failwith "unimplemented"
    let fwmkeys t ?max prefix = failwith "unimplemented"
    let genuid t = failwith "unimplemented"
    let get t pkey = failwith "unimplemented"
    let iterinit t = failwith "unimplemented"
    let iternext t = failwith "unimplemented"
    let open_ t ?omode path = failwith "unimplemented"
    let optimize t ?bnum ?apow ?fpow ?opts () = failwith "unimplemented"
    let out t pkey = failwith "unimplemented"
    let path t = failwith "unimplemented"
    let put t pkey cols = failwith "unimplemented"
    let putcat t pkey cols = failwith "unimplemented"
    let putkeep t pkey cols = failwith "unimplemented"
    let rnum t = failwith "unimplemented"
    let setcache t ?rcnum ?lcnum ?ncnum () = failwith "unimplemented"
    let setdfunit t dfunit = failwith "unimplemented"
    let setindex t name itype = failwith "unimplemented"
    let setxmsiz t xmsiz = failwith "unimplemented"
    let sync t = failwith "unimplemented"
    let tranabort t = failwith "unimplemented"
    let tranbegin t = failwith "unimplemented"
    let trancommit t = failwith "unimplemented"
    let tune t ?bnum ?apow ?fpow ?opts () = failwith "unimplemented"
    let vanish t = failwith "unimplemented"
    let vsiz t pkey = failwith "unimplemented"
  end

  include Fun (Tclist_list) (Tcmap_list)
end

module TDBQRY =
struct
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

    val addcond : t -> string -> ?negate:bool -> ?noidx:bool -> qcond -> string -> unit
    val hint : t -> string
    val kwic : t -> ?name:string -> ?width:int -> ?opts:kopt list -> tcmap_t -> tclist_t
    val metasearch : t -> ?setop:msetop -> t list -> tclist_t
    val proc : t -> (string -> tcmap_t -> qpost list) -> unit
    val search : t -> tclist_t
    val searchout : t -> unit
    val setlimit : t -> ?max:int -> ?skip:int -> unit -> unit
    val setorder : t -> string -> qord -> unit
  end

  module Fun (Tcl : Tclist_t) (Tcm : Tcmap_t) =
  struct
    type tclist_t = Tcl.t
    type tcmap_t = Tcm.t

    let new_ tdb = failwith "unimplemented"
  
    let addcond t name ?negate ?noidx op expr = failwith "unimplemented"
    let hint t = failwith "unimplemented"
    let kwic t ?name ?width ?opts cols = failwith "unimplemented"
    let metasearch t ?setop others = failwith "unimplemented"
    let proc t func = failwith "unimplemented"
    let search t = failwith "unimplemented"
    let searchout t = failwith "unimplemented"
    let setlimit t ?max ?skip () = failwith "unimplemented"
    let setorder t string qord = failwith "unimplemented"
  end

  include Fun (Tclist_list) (Tcmap_list)  
end
