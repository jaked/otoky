open Tokyo_cabinet

type ('k, 'v) t

val open_ : ?omode:omode list -> 'k Otoky_type.t -> 'v Otoky_type.t -> string -> ('k, 'v) t

val close : ('k, 'v) t -> unit
val copy : ('k, 'v) t -> string -> unit
val fsiz : ('k, 'v) t -> int64
val get : ('k, 'v) t -> 'k -> 'v
val iterinit : ('k, 'v) t -> unit
val iternext : ('k, 'v) t -> 'k
val optimize : ('k, 'v) t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
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
val tune : ('k, 'v) t -> ?bnum:int64 -> ?apow:int -> ?fpow:int -> ?opts:opt list -> unit -> unit
val vanish : ('k, 'v) t -> unit
val vsiz : ('k, 'v) t -> 'k -> int
