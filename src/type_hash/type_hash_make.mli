type update

val update_unit : update
val update_bool : update
val update_char : update

val update_tuple : update list -> update
val update_sum : (string * update list) list -> update
val update_record : (string * update) list -> update
val update_polyvar : [ `Tag of (string * update option) | `Extends of update ] list -> update

val update_list : update -> update
val update_option : update -> update
val update_array : update -> update
val update_hashtbl : update -> update -> update

(* XXX should we bother?
val update_function : update -> update -> update
val update_labeled_function : bool -> string -> update -> update -> update
*)

val make : update -> unit -> 'a Type_hash.t
