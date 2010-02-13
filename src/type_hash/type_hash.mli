type 'a t

val to_hash : 'a t -> string
val to_printable : 'a t -> string

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

val make : s -> 'a t
