type update = (string -> unit) -> unit

let update_unit add = add "unit"
let update_bool add = add "bool"
let update_char add = add "char"

let update_tuple parts add =
  let rec loop = function
    | [] -> ()
    | [ p ] -> p add
    | p :: parts -> p add; add " * "; loop parts in
  add "(";
  loop parts;
  add ")"

let update_sum arms add = failwith "unimplemented"
let update_record fields add = failwith "unimplemented"
let update_polyvar arms add = failwith "unimplemented"

let update_list t add = t add; add " list"
let update_option t add = t add; add " option"
let update_array t add = t add; add " array"
let update_hashtbl k v add = k add; v add; add " Hashtbl.t"

let make update =
  let t = lazy begin
    let b = Buffer.create 256 in
    update (Buffer.add_string b);
    let printable = Buffer.contents b in
    let hash = Cryptokit.hash_string (Cryptokit.Hash.md5 ()) printable in
    Type_hash.make printable hash
  end in
  (fun () -> Lazy.force t)
