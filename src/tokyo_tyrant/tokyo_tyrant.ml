open Tokyo_common

type error =
    | Einvalid
    | Enohost
    | Erefused
    | Esend
    | Erecv
    | Ekeep
    | Enorec
    | Emisc

exception Error of error * string * string

type mopt = Monoulog

type topt = Trecon

module RDB =
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
  (*val mget : t -> ? -> ?*)
    val iterinit : t -> unit
    val iternext : t -> cstr_t
    val misc : t -> ?mopts:mopt list -> string -> tclist_t -> tclist_t
    val open_ : t -> string -> int -> unit
    val optimize : t -> ?params:string -> unit -> unit
    val out : t -> cstr_t -> unit
    val put : t -> cstr_t -> cstr_t -> unit
    val putcat : t -> cstr_t -> cstr_t -> unit
    val putkeep : t -> cstr_t -> cstr_t -> unit
    val putnr : t -> cstr_t -> cstr_t -> unit
    val putshl : t -> ?width:int -> cstr_t -> cstr_t -> unit
    val rnum : t -> int64
    val size : t -> int64
    val stat : t -> string
    val sync : t -> unit
    val tune : t -> ?timeout:float -> ?topts:topt list -> unit -> unit
    val vanish : t -> unit
    val vsiz : t -> cstr_t -> int
  end

  module Fun (Cs : Cstr_t) (Tcl : Tclist_t) =
  struct
    type cstr_t = Cs.t
    type tclist_t = Tcl.t

    external new_ : unit -> t = "otoky_rdb_new"

    external _adddouble : t -> string -> int -> float -> float = "otoky_rdb_adddouble"
    let adddouble t key num = _adddouble t (Cs.string key) (Cs.length key) num

    external _addint : t -> string -> int -> int -> int = "otoky_rdb_addint"
    let addint t key num = _addint t (Cs.string key) (Cs.length key) num

    external close : t -> unit = "otoky_rdb_close"
    external copy : t -> string -> unit = "otoky_rdb_copy"

    external _fwmkeys : t -> ?max:int -> string -> int -> Tclist.t = "otoky_rdb_fwmkeys"
    let fwmkeys t ?max prefix =
      let tclist = _fwmkeys t ?max (Cs.string prefix) (Cs.length prefix) in
      let r = Tcl.of_tclist tclist in
      if Tcl.del then Tclist.del tclist;
      r

    external _get : t -> string -> int -> Cstr.t = "otoky_rdb_get"
    let get t key =
      let cstr = _get t (Cs.string key) (Cs.length key) in
      let r = Cs.of_cstr cstr in
      if Cs.del then Cstr.del cstr;
      r

  (*let mget : t -> ? -> ?*)

    external iterinit : t -> unit = "otoky_rdb_iterinit"

    external _iternext : t -> Cstr.t = "otoky_rdb_iternext"
    let iternext t =
      let cstr = _iternext t in
      let r = Cs.of_cstr cstr in
      if Cs.del then Cstr.del cstr;
      r

    external _misc : t -> ?mopts:mopt list -> string -> Tclist.t -> Tclist.t = "otoky_rdb_misc"
    let misc t ?mopts name args =
      if Tcl.del
      then
        let args_tclist = Tcl.to_tclist args in
        let ret_tclist =
          try _misc t ?mopts name args_tclist
          with e -> Tclist.del args_tclist; raise e in
        Tclist.del args_tclist;
        let r = Tcl.of_tclist ret_tclist in
        Tclist.del ret_tclist;
        r
      else
        Tcl.of_tclist (_misc t ?mopts name (Tcl.to_tclist args))

    external open_ : t -> string -> int -> unit = "otoky_rdb_open"
    external optimize : t -> ?params:string -> unit -> unit = "otoky_rdb_optimize"

    external _out : t -> string -> int -> unit = "otoky_rdb_out"
    let out t key = _out t (Cs.string key) (Cs.length key)

    external _put : t -> string -> int -> string -> int -> unit = "otoky_rdb_put"
    let put t key value = _put t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external _putcat : t -> string -> int -> string -> int -> unit = "otoky_rdb_putcat"
    let putcat t key value = _putcat t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external _putkeep : t -> string -> int -> string -> int -> unit = "otoky_rdb_putkeep"
    let putkeep t key value = _putkeep t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external _putnr : t -> string -> int -> string -> int -> unit = "otoky_rdb_putnr"
    let putnr t key value = _putnr t (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external _putshl : t -> ?width:int -> string -> int -> string -> int -> unit = "otoky_rdb_putshl_bc" "otoky_rdb_putshl"
    let putshl t ?width key value = _putshl t ?width (Cs.string key) (Cs.length key) (Cs.string value) (Cs.length value)

    external rnum : t -> int64 = "otoky_rdb_rnum"
    external size : t -> int64 = "otoky_rdb_size"
    external stat : t -> string = "otoky_rdb_stat"
    external sync : t -> unit = "otoky_rdb_sync"
    external tune : t -> ?timeout:float -> ?topts:topt list -> unit -> unit = "otoky_rdb_tune"
    external vanish : t -> unit = "otoky_rdb_vanish"

    external _vsiz : t -> string -> int -> int = "otoky_rdb_vsiz"
    let vsiz t key = _vsiz t (Cs.string key) (Cs.length key)
  end

  include Fun (Cstr_string) (Tclist_list)
end
