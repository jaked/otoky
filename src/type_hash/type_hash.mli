type 'a t

val to_hash : 'a t -> string
val to_printable : 'a t -> string

val make : string -> string -> 'a t (* for internal use *)
