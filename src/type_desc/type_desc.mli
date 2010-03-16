type 'a t

val equal: 'a t -> 'b t -> bool

val to_string : 'a t -> string

(* private interface *)

type s =
    | Unit
    | Int
    | Int32
    | Int64
    | Float
    | Bool
    | Char
    | String
    | Tuple of s list
    | Sum of (string * s list) list
    | Record of (string * s) list
    | Polyvar of pv_arm list
    | List of s
    | Option of s
    | Array of s
    | Hashtbl of s * s
    | Var of int
    | Bundle of s list
    | Project of int * s
and pv_arm =
    | Tag of string * s option
    | Extend of s

val hide : s -> 'a t
val show : 'a t -> s
