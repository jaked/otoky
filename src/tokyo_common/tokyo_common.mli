module Cstr :
sig
  type t = string * int
  type buf = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

  external del : t -> unit = "otoky_cstr_del"
  external to_bigarray : t -> buf = "otoky_cstr_to_bigarray"
  external of_bigarray : ?len:int -> buf -> t = "otoky_cstr_of_bigarray"
  val copy : t -> string
  val of_string : string -> t
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

module Cstr_string : Cstr_t with type t = string
module Cstr_cstr : Cstr_t with type t = Cstr.t

module Tclist :
sig
  type t

  external new_ : ?anum:int -> unit -> t = "otoky_tclist_new"
  external del : t -> unit = "otoky_tclist_del"
  external num : t -> int = "otoky_tclist_num"
  external val_ : t -> int -> int ref -> string = "otoky_tclist_val"
  external push : t -> string -> int -> unit = "otoky_tclist_push"
  external lsearch : t -> string -> int -> int = "otoky_tclist_lsearch"
  external bsearch : t -> string -> int -> int = "otoky_tclist_bsearch"

  val copy_val : t -> int -> string
end

module Tcmap :
sig
  type t

  external new_ : ?bnum:int32 -> unit -> t = "otoky_tcmap_new"
  external clear : t -> unit = "otoky_tcmap_clear"
  external del : t -> unit = "otoky_tcmap_del"
  external put : t -> string -> int -> string -> int -> unit = "otoky_tcmap_put"
  external putcat : t -> string -> int -> string -> int -> unit = "otoky_tcmap_putcat"
  external putkeep : t -> string -> int -> string -> int -> unit = "otoky_tcmap_putkeep"
  external out : t -> string -> int -> unit = "otoky_tcmap_out"
  external get : t -> string -> int -> int ref -> string = "otoky_tcmap_get"
  external iterinit : t -> unit = "otoky_tcmap_iterinit"
  external iternext : t -> int ref -> string = "otoky_tcmap_iternext"
  external rnum : t -> int64 = "otoky_tcmap_rnum"
  external msiz : t -> int64 = "otoky_tcmap_msiz"
  external keys : t -> Tclist.t = "otoky_tcmap_keys"
  external vals : t -> Tclist.t = "otoky_tcmap_vals"

  val copy_get : t -> string -> int -> string
  val copy_iternext : t -> string
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
  val replace_tcmap : t -> Tcmap.t -> unit
end

module Tclist_list : Tclist_t with type t = string list
module Tclist_array : Tclist_t with type t = string array
module Tclist_tclist : Tclist_t with type t = Tclist.t

module Tcmap_list : Tcmap_t with type t = (string * string) list
module Tcmap_array : Tcmap_t with type t = (string * string) array
module Tcmap_hashtbl : Tcmap_t with type t = (string, string) Hashtbl.t
module Tcmap_tcmap : Tcmap_t with type t = Tcmap.t
