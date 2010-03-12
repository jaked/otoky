open Tokyo_common
open Tokyo_cabinet

module Type =
struct
  include Otoky_type

  let type_desc_hash_key = "__otoky_type_desc_hash__"

  let is_type_desc_hash_key k klen =
    (* argh. maybe we should store the type_desc hash somewhere else. but where? *)
    if klen <> String.length type_desc_hash_key
    then false
    else
      let rec loop i =
        if i = klen then true
        else if String.unsafe_get k i <> String.unsafe_get type_desc_hash_key i then false
        else loop (i + 1) in
      loop 0

  let marshall_key t k func =
    let (k, klen) as mk = t.marshall k in
    if is_type_desc_hash_key k klen
    then raise (Error (Einvalid, func, "marshalled value is type_desc_hash key"))
    else mk
end

module HDB_raw = HDB.Fun (Cstr_cstr) (Tclist_tclist)

type ('k, 'v) t = {
  hdb : HDB.t;
  ktype : 'k Type.t;
  vtype : 'v Type.t;
}

let open_ ?omode ktype vtype fn =
  let hdb = HDB.new_ () in
  HDB.open_ hdb ?omode fn;
  let hash = Type.type_desc_hash ktype ^ Type.type_desc_hash vtype in
  begin try
    if hash <> HDB.get hdb Type.type_desc_hash_key
    then begin
      HDB.close hdb;
      raise (Error (Einvalid, "open_", "bad type_desc hash"))
    end
  with Error (Enorec, _, _) ->
    (* XXX maybe should check that this is a fresh db? *)
    HDB.put hdb Type.type_desc_hash_key hash;
  end;
  {
    hdb = hdb;
    ktype = ktype;
    vtype = vtype;
  }

let close t = HDB.close t.hdb
let copy t fn = HDB.copy t.hdb fn
let fsiz t = HDB.fsiz t.hdb

let get t k =
  let cstr = HDB_raw.get t.hdb (Type.marshall_key t.ktype k "get") in
  try
    let v = t.vtype.Type.unmarshall cstr in
    Cstr.del cstr;
    v
  with e -> Cstr.del cstr; raise e

let iterinit t = HDB.iterinit t.hdb

let iternext t =
  let (k, klen) as cstr = HDB_raw.iternext t.hdb in
  let cstr =
    if Type.is_type_desc_hash_key k klen
    then (Cstr.del cstr; HDB_raw.iternext t.hdb)
    else cstr in
  let k = t.ktype.Type.unmarshall cstr in
  Cstr.del cstr;
  k

let optimize t ?bnum ?apow ?fpow ?opts () = HDB.optimize t.hdb ?bnum ?apow ?fpow ?opts ()
let out t k = HDB_raw.out t.hdb (Type.marshall_key t.ktype k "out")
let path t = HDB.path t.hdb
let put t k v = HDB_raw.put t.hdb (Type.marshall_key t.ktype k "put") (t.vtype.Type.marshall v)
let putasync t k v = HDB_raw.putasync t.hdb (Type.marshall_key t.ktype k "putasync") (t.vtype.Type.marshall v)
let putkeep t k v = HDB_raw.putkeep t.hdb (Type.marshall_key t.ktype k "putkeep") (t.vtype.Type.marshall v)
let rnum t = HDB.rnum t.hdb
let setcache t rcnum = HDB.setcache t.hdb rcnum
let setdfunit t dfunit = HDB.setdfunit t.hdb dfunit
let setxmsiz t xmsiz = HDB.setxmsiz t.hdb xmsiz
let sync t = HDB.sync t.hdb
let tranabort t = HDB.tranabort t.hdb
let tranbegin t = HDB.tranbegin t.hdb
let trancommit t = HDB.trancommit t.hdb
let tune t ?bnum ?apow ?fpow ?opts () = HDB.tune t.hdb ?bnum ?apow ?fpow ?opts ()
let vanish t = HDB.vanish t.hdb
let vsiz t k = HDB_raw.vsiz t.hdb (Type.marshall_key t.ktype k "vsiz")
