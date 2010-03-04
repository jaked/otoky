module Cstr =
struct
  type t = string * int

  external del : t -> unit = "otoky_cstr_del"
  external to_bigarray : t -> (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t = "otoky_cstr_to_bigarray"

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

  let del = true

  let of_cstr = Cstr.copy
  let to_cstr = Cstr.of_string

  let string t = t
  let length t = String.length t
end

module Cstr_cstr =
struct
  type t = Cstr.t

  let del = false

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

  let copy_val t k =
    let len = ref 0 in
    let s = val_ t k len in
    let r = String.create !len in
    String.unsafe_blit s 0 r 0 !len;
    r
end

module Tcmap =
struct
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

  let copy_get t k klen =
    let vlen = ref 0 in
    let s = get t k klen vlen in
    let v = String.create !vlen in
    String.unsafe_blit s 0 v 0 !vlen;
    v

  let copy_iternext t =
    let len = ref 0 in
    let s = iternext t len in
    let r = String.create !len in
    String.unsafe_blit s 0 r 0 !len;
    r
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

  let of_tcmap tcmap =
    let rec loop () =
      try
        let k = Tcmap.copy_iternext tcmap in
        let v = Tcmap.copy_get tcmap k (String.length k) in
        (k, v) :: loop ()
      with Not_found -> [] in
    Tcmap.iterinit tcmap;
    loop ()

  let to_tcmap t =
    let tcmap = Tcmap.new_ () in
    List.iter (fun (k, v) -> Tcmap.put tcmap k (String.length k) v (String.length v)) t;
    tcmap

  let replace_tcmap t tcmap =
    Tcmap.clear tcmap;
    List.iter (fun (k, v) -> Tcmap.put tcmap k (String.length k) v (String.length v)) t
end

module Tcmap_array =
struct
  type t = (string * string) array

  let del = true

  let of_tcmap tcmap =
    let rnum = Int64.to_int (Tcmap.rnum tcmap) in
    let a = Array.make rnum ("","") in
    Tcmap.iterinit tcmap;
    for i = 0 to rnum -1 do
      let k = Tcmap.copy_iternext tcmap in
      let v = Tcmap.copy_get tcmap k (String.length k) in
      a.(i) <- (k, v)
    done;
    a

  let to_tcmap t =
    let tcmap = Tcmap.new_ () in
    Array.iter (fun (k, v) -> Tcmap.put tcmap k (String.length k) v (String.length v)) t;
    tcmap

  let replace_tcmap t tcmap =
    Tcmap.clear tcmap;
    Array.iter (fun (k, v) -> Tcmap.put tcmap k (String.length k) v (String.length v)) t
end

module Tcmap_hashtbl =
struct
  type t = (string, string) Hashtbl.t

  let del = true

  let of_tcmap tcmap =
    let rnum = Int64.to_int (Tcmap.rnum tcmap) in
    let h = Hashtbl.create rnum in
    Tcmap.iterinit tcmap;
    for i = 0 to rnum -1 do
      let k = Tcmap.copy_iternext tcmap in
      let v = Tcmap.copy_get tcmap k (String.length k) in
      Hashtbl.replace h k v
    done;
    h

  let to_tcmap t =
    let tcmap = Tcmap.new_ () in
    Hashtbl.iter (fun k v -> Tcmap.put tcmap k (String.length k) v (String.length v)) t;
    tcmap

  let replace_tcmap t tcmap =
    Tcmap.clear tcmap;
    Hashtbl.iter (fun k v -> Tcmap.put tcmap k (String.length k) v (String.length v)) t
end

module Tcmap_tcmap =
struct
  type t = Tcmap.t

  let del = false

  external of_tcmap : Tcmap.t -> t = "%identity"
  external to_tcmap : t -> Tcmap.t = "%identity"

  let replace_tcmap t tcmap =
    if not (t == tcmap)
    then invalid_arg "replace_tcmap"
end
