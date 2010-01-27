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

exception Error of error * string * string

let _ = Callback.register_exception "Tokyo_cabinet.Error" (Error (Emisc, "", ""))

type omode = Oreader | Owriter | Ocreat | Otrunc | Onolck | Olcknb | Otsync

type opt = Tlarge | Tdeflate | Tbzip | Ttcbs

module Cstr =
struct
  type t = string * int

  external del : t -> unit = "otoky_cstr_del"

  let copy (s, len) =
    let r = String.create len in
    String.unsafe_blit s 0 r 0 len;
    r

  let of_string s =
    s, String.length s
end

module type Cstr_t =
sig
  type t

  val del : bool

  val of_cstr : Cstr.t -> t
  val to_cstr : t -> Cstr.t

  val string : t -> string
  val length : t -> int
end

module Cstr_string =
struct
  type t = string

  let del = false

  let of_cstr = Cstr.copy
  let to_cstr = Cstr.of_string

  let string t = t
  let length t = String.length t
end

module Cstr_cstr =
struct
  type t = Cstr.t

  let del = true

  external of_cstr : Cstr.t -> t = "%identity"
  external to_cstr : Cstr.t -> t = "%identity"

  let string (t, _) = t
  let length (_, len) = len
end

module Tclist =
struct
  type t

  external new_ : ?anum:int -> unit -> t = "otoky_tclist_new"
  external del : t -> unit = "otoky_tclist_del"
  external num : t -> int = "otoky_tclist_num"
  external val_ : t -> int -> int ref -> string = "otoky_tclist_val"
  external push : t -> string -> int -> unit = "otoky_tclist_push"
  external lsearch : t -> string -> int -> int = "otoky_tclist_lsearch"
  external bsearch : t -> string -> int -> int = "otoky_tclist_bsearch"

  let copy_val tclist k =
    let len = ref 0 in
    let s = val_ tclist k len in
    let r = String.create !len in
    String.unsafe_blit s 0 r 0 !len;
    r
end

module Tcmap =
struct
  type t

end

module type Tclist_t =
sig
  type t

  val del : bool

  val of_tclist : Tclist.t -> t
  val to_tclist : t -> Tclist.t
end

module type Tcmap_t =
sig
  type t

  val del : bool

  val of_tcmap : Tcmap.t -> t
  val to_tcmap : t -> Tcmap.t
end

module Tclist_list =
struct
  type t = string list

  let del = true

  let of_tclist tclist =
    let num = Tclist.num tclist in
    let rec loop k =
      if k = num
      then []
      else Tclist.copy_val tclist k :: loop (k + 1) in
    loop 0

  let to_tclist t =
    let anum = List.length t in
    let tclist = Tclist.new_ ~anum () in
    List.iter (fun s -> Tclist.push tclist s (String.length s)) t;
    tclist
end

module Tclist_array =
struct
  type t = string array

  let del = true

  let of_tclist tclist =
    Array.init (Tclist.num tclist) (Tclist.copy_val tclist)

  let to_tclist t =
    let anum = Array.length t in
    let tclist = Tclist.new_ ~anum () in
    Array.iter (fun s -> Tclist.push tclist s (String.length s)) t;
    tclist
end

module Tclist_tclist =
struct
  type t = Tclist.t

  let del = false

  external of_tclist : Tclist.t -> t = "%identity"
  external to_tclist : t -> Tclist.t = "%identity"
end

module Tcmap_list =
struct
  type t = (string * string) list

  let del = true

  let of_tcmap tcmap = failwith "unimplemented"
  let to_tcmap t = failwith "unimplemented"
end

module Tcmap_array =
struct
  type t = (string * string) array

  let del = true

  let of_tcmap tcmap = failwith "unimplemented"
  let to_tcmap t = failwith "unimplemented"
end

module Tcmap_hashtbl =
struct
  type t = (string, string) Hashtbl.t

  let del = true

  let of_tcmap tcmap = failwith "unimplemented"
  let to_tcmap t = failwith "unimplemented"
end

module Tcmap_tcmap =
struct
  type t = Tcmap.t

  let del = false

  external of_tcmap : Tcmap.t -> t = "%identity"
  external to_tcmap : t -> Tcmap.t = "%identity"
end

module ADB =
struct
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

  module Fun (Cs : Cstr_t) (Tcl : Tclist_t) =
  struct
    type cstr_t = Cs.t
    type tclist_t = Tcl.t

    external new_ : unit -> t = "otoky_adb_new"

    external _adddouble : t -> string -> int -> float -> float = "otoky_adb_adddouble"
    let adddouble t key num = _adddouble t (Cs.string key) (Cs.length key) num

    external _addint : t -> string -> int -> int -> int = "otoky_adb_addint"
    let addint t key num = _addint t (Cs.string key) (Cs.length key) num

    external close : t -> unit = "otoky_adb_close"
    external copy : t -> string -> unit = "otoky_adb_copy"

    external _fwmkeys : t -> ?max:int -> string -> int -> Tclist.t = "otoky_adb_fwmkeys"
    let fwmkeys t ?max prefix =
      let tclist = _fwmkeys t ?max (Cs.string prefix) (Cs.length prefix) in
      let r = Tcl.of_tclist tclist in
      if Tcl.del then Tclist.del tclist;
      r

    external _get : t -> string -> int -> Cstr.t = "otoky_adb_get"
    let get t key =
      let cstr = _get t (Cs.string key) (Cs.length key) in
      let r = Cs.of_cstr cstr in
      if Cs.del then Cstr.del cstr;
      r

    external iterinit : t -> unit = "otoky_adb_iterinit"

    external _iternext : t -> Cstr.t = "otoky_adb_iternext"
    let iternext t =
      let cstr = _iternext t in
      let r = Cs.of_cstr cstr in
      if Cs.del then Cstr.del cstr;
      r

    external _misc : t -> string -> Tclist.t -> Tclist.t = "otoky_adb_misc"
    let misc t name args =
      if Tcl.del
      then
        let args_tclist = Tcl.to_tclist args in
        let ret_tclist =
          try _misc t name args_tclist
          with e -> Tclist.del args_tclist; raise e in
        Tclist.del args_tclist;
        let r = Tcl.of_tclist ret_tclist in
        Tclist.del ret_tclist;
        r
      else
        Tcl.of_tclist (_misc t name (Tcl.to_tclist args))

    external open_ : t -> string -> unit = "otoky_adb_open"
    external optimize : t -> ?params:string -> unit -> unit = "otoky_adb_optimize"

    external _out : t -> string -> int -> unit = "otoky_adb_out"
    let out t key = _out t (Cs.string key) (Cs.length key)

    external path : t -> string = "otoky_adb_path"

    external _put : t -> string -> int -> string -> int -> unit = "otoky_adb_put"
    let put t key value = _put t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external _putcat : t -> string -> int -> string -> int -> unit = "otoky_adb_putcat"
    let putcat t key value = _putcat t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external _putkeep : t -> string -> int -> string -> int -> unit = "otoky_adb_putkeep"
    let putkeep t key value = _putkeep t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external rnum : t -> int64 = "otoky_adb_rnum"
    external size : t -> int64 = "otoky_adb_size"
    external sync : t -> unit = "otoky_adb_sync"
    external tranabort : t -> unit = "otoky_adb_tranabort"
    external tranbegin : t -> unit = "otoky_adb_tranbegin"
    external trancommit : t -> unit = "otoky_adb_trancommit"
    external vanish : t -> unit = "otoky_adb_vanish"

    external _vsiz : t -> string -> int -> int = "otoky_adb_vsiz"
    let vsiz t key = _vsiz t (Cs.string key) (Cs.length key)
  end

  include Fun (Cstr_string) (Tclist_list)
end

module BDB =
struct
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
    val open_ : t -> ?mode:omode list -> string -> unit
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

  module Fun (Cs : Cstr_t) (Tcl : Tclist_t) =
  struct
    type cstr_t = Cs.t
    type tclist_t = Tcl.t

    external new_ : unit -> t = "otoky_bdb_new"

    external _adddouble : t -> string -> int -> float -> float = "otoky_bdb_adddouble"
    let adddouble t key num = _adddouble t (Cs.string key) (Cs.length key) num

    external _addint : t -> string -> int -> int -> int = "otoky_bdb_addint"
    let addint t key num = _addint t (Cs.string key) (Cs.length key) num

    external close : t -> unit = "otoky_bdb_close"
    external copy : t -> string -> unit = "otoky_bdb_copy"
    external fsiz : t -> int64 = "otoky_bdb_fsiz"

    external _fwmkeys : t -> ?max:int -> string -> int -> Tclist.t = "otoky_bdb_fwmkeys"
    let fwmkeys t ?max prefix =
      let tclist = _fwmkeys t ?max (Cs.string prefix) (Cs.length prefix) in
      let r = Tcl.of_tclist tclist in
      if Tcl.del then Tclist.del tclist;
      r

    external _get : t -> string -> int -> Cstr.t = "otoky_bdb_get"
    let get t key =
      let cstr = _get t (Cs.string key) (Cs.length key) in
      let r = Cs.of_cstr cstr in
      if Cs.del then Cstr.del cstr;
      r

    external _getlist : t -> string -> int -> Tclist.t = "otoky_bdb_getlist"
    let getlist t key =
      let tclist = _getlist t (Cs.string key) (Cs.length key) in
      let r = Tcl.of_tclist tclist in
      if Tcl.del then Tclist.del tclist;
      r

    external open_ : t -> ?mode:omode list -> string -> unit = "otoky_bdb_open"
    external optimize :
      t -> ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit =
          "otoky_bdb_optimize_bc" "otoky_bdb_optimize"

    external _out : t -> string -> int -> unit = "otoky_bdb_out"
    let out t key = _out t (Cs.string key) (Cs.length key)

    external _outlist : t -> string -> int -> unit = "otoky_bdb_outlist"
    let outlist t key = _outlist t (Cs.string key) (Cs.length key)

    external path : t -> string = "otoky_bdb_path"

    external _put : t -> string -> int -> string -> int -> unit = "otoky_bdb_put"
    let put t key value = _put t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external _putcat : t -> string -> int -> string -> int -> unit = "otoky_bdb_putcat"
    let putcat t key value = _putcat t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external _putdup : t -> string -> int -> string -> int -> unit = "otoky_bdb_putdup"
    let putdup t key value = _putdup t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external _putkeep : t -> string -> int -> string -> int -> unit = "otoky_bdb_putkeep"
    let putkeep t key value = _putkeep t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external _putlist : t -> string -> int -> Tclist.t -> unit = "otoky_bdb_putlist"
    let putlist t key vals =
      if Tcl.del
      then
        let vals_tclist = Tcl.to_tclist vals in
        begin
          try _putlist t (Cs.string key) (Cs.length key) vals_tclist
          with e -> Tclist.del vals_tclist; raise e
        end;
        Tclist.del vals_tclist
      else
        _putlist t (Cs.string key) (Cs.length key) (Tcl.to_tclist vals)

    external _range :
      t -> ?bkey:string -> blen:int -> ?binc:bool -> ?ekey:string -> elen:int -> ?einc:bool -> ?max:int -> unit -> Tclist.t =
      "otoky_bdb_range_bc" "otoky_bdb_range"
    let range t ?bkey ?binc ?ekey ?einc ?max () =
      let bkey, blen = match bkey with None -> None, -1 | Some key -> Some (Cs.string key), (Cs.length key) in
      let ekey, elen = match ekey with None -> None, -1 | Some key -> Some (Cs.string key), (Cs.length key) in
      let tclist = _range t ?bkey ~blen ?binc ?ekey ~elen ?einc ?max () in
      let r = Tcl.of_tclist tclist in
      if Tcl.del then Tclist.del tclist;
      r

    external rnum : t -> int64 = "otoky_bdb_rnum"
    external setcache : t -> ?lcnum:int32 -> ?ncnum:int32 -> unit -> unit = "otoky_bdb_setcache"
    external setcmpfunc : t -> cmpfunc -> unit = "otoky_bdb_setcmpfunc"
    external setdfunit : t -> int32 -> unit = "otoky_bdb_setdfunit"
    external setxmsiz : t -> int64 -> unit = "otoky_bdb_setxmsiz"

    external sync : t -> unit = "otoky_bdb_sync"
    external tranabort : t -> unit = "otoky_bdb_tranabort"
    external tranbegin : t -> unit = "otoky_bdb_tranbegin"
    external trancommit : t -> unit = "otoky_bdb_trancommit"
    external tune :
      t -> ?lmemb:int32 -> ?nmemb:int32 -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit =
          "otoky_bdb_tune_bc" "otoky_bdb_tune"
    external vanish : t -> unit = "otoky_bdb_vanish"

    external _vnum : t -> string -> int -> int = "otoky_bdb_vnum"
    let vnum t key = _vnum t (Cs.string key) (Cs.length key)

    external _vsiz : t -> string -> int -> int = "otoky_bdb_vsiz"
    let vsiz t key = _vsiz t (Cs.string key) (Cs.length key)
  end

  include Fun (Cstr_string) (Tclist_list)
end

module BDBCUR =
struct
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
    val put : t -> cstr_t -> cpmode -> unit
    val val_ : t -> cstr_t
  end

  module Fun (Cs : Cstr_t) =
  struct
    type cstr_t = Cs.t

    let new_ bdb = failwith "unimplemented"
    (* external new_ : BDB.t -> t = "otoky_bdbcur_new" *)
  
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

  include Fun (Cstr_string)
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
