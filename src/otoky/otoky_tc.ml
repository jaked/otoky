open Tokyo_common
open Tokyo_cabinet

module Type =
struct
  type 'a t = {
    type_desc : 'a Type_desc.t;
    marshall : 'a -> Cstr.t;
    unmarshall : Cstr.t -> 'a;
    compare : 'a -> 'a -> int; (* only needed for BDB *)
  }

  let make ~type_desc ~marshall ~unmarshall ~compare = {
    type_desc = type_desc;
    marshall = marshall;
    unmarshall = unmarshall;
    compare = compare;
  }

  let type_desc_hash t =
    Digest.string (Type_desc.to_string t.type_desc)

  let type_desc_hash_key = "__otoky_type_desc_hash__"

  let is_type_desc_hash_key k klen =
    if klen <> String.length type_desc_hash_key
    then false
    else
      let rec loop i =
        if i = klen then true
        else if String.unsafe_get k i <> String.unsafe_get type_desc_hash_key i then false
        else loop (i + 1) in
      loop 0

  let compare_cstr t a alen b blen =
    (* argh. maybe we should store the type_desc hash somewhere else. but where? *)
    match is_type_desc_hash_key a alen, is_type_desc_hash_key b blen with
      | true, true -> 0
      | true, false -> -1
      | false, true -> 1
      | _ -> t.compare (t.unmarshall (a, alen)) (t.unmarshall (b, blen))
end

module BDB =
struct
  module BDB_raw = BDB.Fun (Cstr_cstr) (Tclist_tclist)

  type ('k, 'v) t = {
    bdb : BDB.t;
    ktype : 'k Type.t;
    vtype : 'v Type.t;
  }

  let open_ ?omode ktype vtype fn =
    let bdb = BDB.new_ () in
    BDB.setcmpfunc bdb (BDB.Cmp_custom_cstr (Type.compare_cstr ktype));
    BDB.open_ bdb ?omode fn;
    let hash = Type.type_desc_hash ktype ^ Type.type_desc_hash vtype in
    begin try
      if hash <> BDB.get bdb Type.type_desc_hash_key
      then begin
        BDB.close bdb;
        raise (Error (Einvalid, "bad type_desc hash", "open_"))
      end
    with Error (Enorec, _, _) ->
      (* XXX maybe should check that this is a fresh db? *)
      BDB.put bdb Type.type_desc_hash_key hash;
    end;
    {
      bdb = bdb;
      ktype = ktype;
      vtype = vtype;
    }

  let close t = BDB.close t.bdb
  let copy t fn = BDB.copy t.bdb fn
  let fsiz t = BDB.fsiz t.bdb

  let get t k =
    let cstr = BDB_raw.get t.bdb (t.ktype.Type.marshall k) in
    try
      let v = t.vtype.Type.unmarshall cstr in
      Cstr.del cstr;
      v
    with e -> Cstr.del cstr; raise e

  let getlist t k =
    let tclist = BDB_raw.getlist t.bdb (t.ktype.Type.marshall k) in
    try
      let num = Tclist.num tclist in
      let len = ref 0 in
      let rec loop k =
        if k = num
        then []
        else
          let v = Tclist.val_ tclist k len in
          t.vtype.Type.unmarshall (v, !len) :: loop (k + 1) in
      let r = loop 0 in
      Tclist.del tclist;
      r
    with e -> Tclist.del tclist; raise e

  let optimize t ?lmemb ?nmemb ?bnum ?apow ?fpow ?opts () =
    BDB.optimize t.bdb ?lmemb ?nmemb ?bnum ?apow ?fpow ?opts ()

  let out t k = BDB_raw.out t.bdb (t.ktype.Type.marshall k)
  let outlist t k = BDB_raw.outlist t.bdb (t.ktype.Type.marshall k)
  let path t = BDB.path t.bdb
  let put t k v = BDB_raw.put t.bdb (t.ktype.Type.marshall k) (t.vtype.Type.marshall v)
  let putdup t k v = BDB_raw.putdup t.bdb (t.ktype.Type.marshall k) (t.vtype.Type.marshall v)
  let putkeep t k v = BDB_raw.putkeep t.bdb (t.ktype.Type.marshall k) (t.vtype.Type.marshall v)
  let putlist t k vs = failwith "unimplemented"

  let range t ?bkey ?binc ?ekey ?einc ?max () = failwith "unimplemented"

  let rnum t = BDB.rnum t.bdb
  let setcache t ?lcnum ?ncnum () = BDB.setcache t.bdb ?lcnum ?ncnum ()
  let setdfunit t dfunit = BDB.setdfunit t.bdb dfunit
  let setxmsiz t xmsiz = BDB.setxmsiz t.bdb xmsiz
  let sync t = BDB.sync t.bdb
  let tranabort t = BDB.tranabort t.bdb
  let tranbegin t = BDB.tranbegin t.bdb
  let trancommit t = BDB.trancommit t.bdb

  let tune t ?lmemb ?nmemb ?bnum ?apow ?fpow ?opts () =
    BDB.tune t.bdb ?lmemb ?nmemb ?bnum ?apow ?fpow ?opts ()

  let vanish t = BDB.vanish t.bdb
  let vnum t k = failwith "unimplemented"
  let vsiz t k = failwith "unimplemented"
end

module BDBCUR =
struct
  type ('k, 'v) t = {
    bdbcur : BDBCUR.t;
    ktype : 'k Type.t;
    vtype : 'v Type.t;
  }

  let new_ bdb = failwith "unimplemented"

  let first t = failwith "unimplemented"
  let jump t k = failwith "unimplemented"
  let key t = failwith "unimplemented"
  let last t = failwith "unimplemented"
  let next t = failwith "unimplemented"
  let out t = failwith "unimplemented"
  let prev t = failwith "unimplemented"
  let put t ?cpmode v = failwith "unimplemented"
  let val_ t = failwith "unimplemented"
end

module FDB =
struct
  type 'v t = {
    fdb : FDB.t;
    vtype : 'v Type.t;
  }

  let open_ ?omode vtype fn = failwith "unimplemented"

  let close t = failwith "unimplemented"
  let copy t fn = failwith "unimplemented"
  let fsiz t = failwith "unimplemented"
  let get t k = failwith "unimplemented"
  let iterinit t = failwith "unimplemented"
  let iternext t = failwith "unimplemented"
  let optimize t ?width ?limsiz () = failwith "unimplemented"
  let out t k = failwith "unimplemented"
  let path t = failwith "unimplemented"
  let put t k v = failwith "unimplemented"
  let putkeep t k v = failwith "unimplemented"
  let range t ?max:int spec = failwith "unimplemented"
  let rnum t = failwith "unimplemented"
  let sync t = failwith "unimplemented"
  let tranabort t = failwith "unimplemented"
  let tranbegin t = failwith "unimplemented"
  let trancommit t = failwith "unimplemented"
  let tune t ?width ?limsiz () = failwith "unimplemented"
  let vanish t = failwith "unimplemented"
  let vsiz t k = failwith "unimplemented"
end

module HDB =
struct
  type ('k, 'v) t = {
    hdb : HDB.t;
    ktype : 'k Type.t;
    vtype : 'v Type.t;
  }

  let open_ ?omode ktype vtype fn = failwith "unimplemented"

  let close t = failwith "unimplemented"
  let copy t fn = failwith "unimplemented"
  let fsiz t = failwith "unimplemented"
  let get t k = failwith "unimplemented"
  let iterinit t = failwith "unimplemented"
  let iternext t = failwith "unimplemented"
  let optimize t ?bnum ?apow ?fpow ?opts () = failwith "unimplemented"
  let out t k = failwith "unimplemented"
  let path t = failwith "unimplemented"
  let put t k v = failwith "unimplemented"
  let putasync t k v = failwith "unimplemented"
  let putkeep t k v = failwith "unimplemented"
  let rnum t = failwith "unimplemented"
  let setcache t cache = failwith "unimplemented"
  let setdfunit t dfunit = failwith "unimplemented"
  let setxmsiz t xmsiz = failwith "unimplemented"
  let sync t = failwith "unimplemented"
  let tranabort t = failwith "unimplemented"
  let tranbegin t = failwith "unimplemented"
  let trancommit t = failwith "unimplemented"
  let tune t ?bnum ?apow ?fpow ?opts () = failwith "unimplemented"
  let vanish t = failwith "unimplemented"
  let vsiz t k = failwith "unimplemented"
end
