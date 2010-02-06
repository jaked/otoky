type 'a t = string * string

let to_hash (_, hash) = hash
let to_printable (printable, _) = printable

let make printable hash = (printable, hash)
