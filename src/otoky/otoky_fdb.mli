open Tokyo_cabinet

type 'v t

val open_ : ?omode:omode list -> ?width:int32 -> 'v Otoky_type.t -> string -> 'v t

val close : 'v t -> unit
val copy : 'v t -> string -> unit
val fsiz : 'v t -> int64
val get : 'v t -> int64 -> 'v
val iterinit : 'v t -> unit
val iternext : 'v t -> int64
val optimize : 'v t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
val out : 'v t -> int64 -> unit
val path : 'v t -> string
val put : 'v t -> int64 -> 'v -> unit
val putkeep : 'v t -> int64 -> 'v -> unit
val range : 'v t -> ?lower:int64 -> ?upper:int64 -> ?max:int -> unit -> int64 array
val rnum : 'v t -> int64
val sync : 'v t -> unit
val tranabort : 'v t -> unit
val tranbegin : 'v t -> unit
val trancommit : 'v t -> unit
val tune : 'v t -> ?width:int32 -> ?limsiz:int64 -> unit -> unit
val vanish : 'v t -> unit
val vsiz : 'v t -> int64 -> int
