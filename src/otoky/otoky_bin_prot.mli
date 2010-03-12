open Tokyo_common

val marshall : 'a Bin_prot.Type_class.t -> 'a -> Cstr.t
val unmarshall : 'a Bin_prot.Type_class.t -> Cstr.t -> 'a
