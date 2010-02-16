type 'a t

val equal: 'a t -> 'a t -> bool

val to_string : 'a t -> string

(* private interface *)

type s = [
| `Unit
| `Int
| `Int32
| `Int64
| `Float
| `Bool
| `Char
| `String
| `Tuple of s list
| `Sum of (string * s list) list
| `Record of (string * s) list
| `Polyvar of [ `Tag of string * s option | `Extend of s ] list
| `List of s
| `Option of s
| `Array of s
| `Hashtbl of s * s
| `Var of string
| `Bundle of (string * s) list
| `Project of string * s
]

val hide : s -> 'a t
val show : 'a t -> s
