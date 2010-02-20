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

module RDB :
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

  include Sig with type cstr_t = string and type tclist_t = string list

  module Fun (Cs : Cstr_t) (Tcl : Tclist_t) : Sig with type cstr_t = Cs.t and type tclist_t = Tcl.t
end
