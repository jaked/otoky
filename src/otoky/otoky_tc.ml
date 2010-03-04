type 'a typ = {
  type_desc : 'a Type_desc.t;
  marshall : 'a -> Tokyo_common.Cstr.t;
  unmarshall : Tokyo_common.Cstr.t -> 'a;
  compare : 'a -> 'a -> int; (* only needed for BDB *)
}

module BDB =
struct
  type ('k, 'v) t = {
    bdb : Tokyo_cabinet.BDB.t;
    ktyp : 'k typ;
    vtyp : 'v typ;
  }

  let open_ ?omode ktyp vtyp fn = failwith "unimplemented"

  let close t = failwith "unimplemented"
  let copy t fn = failwith "unimplemented"
  let fsiz t = failwith "unimplemented"
  let get t k = failwith "unimplemented"
  let getlist t k = failwith "unimplemented"

  let optimize t ?lmemb ?nmemb ?bnum ?apow ?fpow ?opts () = failwith "unimplemented"

  let out t k = failwith "unimplemented"
  let outlist t k = failwith "unimplemented"
  let path t = failwith "unimplemented"
  let put t k v = failwith "unimplemented"
  let putdup t k v = failwith "unimplemented"
  let putkeep t k v = failwith "unimplemented"
  let putlist t k vs = failwith "unimplemented"

  let range t ?bkey ?binc ?ekey ?einc ?max () = failwith "unimplemented"

  let rnum t = failwith "unimplemented"
  let setcache t ?lcnum ?ncnum () = failwith "unimplemented"
  let setdfunit t dfunit = failwith "unimplemented"
  let setxmsiz t xmsiz = failwith "unimplemented"
  let sync t = failwith "unimplemented"
  let tranabort t = failwith "unimplemented"
  let tranbegin t  = failwith "unimplemented"
  let trancommit t = failwith "unimplemented"

  let tune t ?lmemb ?nmemb ?bnum ?apow ?fpow ?opts () = failwith "unimplemented"

  let vanish t = failwith "unimplemented"
  let vnum t k = failwith "unimplemented"
  let vsiz t k = failwith "unimplemented"
end

module BDBCUR =
struct
  type ('k, 'v) t = {
    bdbcur : Tokyo_cabinet.BDBCUR.t;
    ktyp : 'k typ;
    vtyp : 'v typ;
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
    fdb : Tokyo_cabinet.FDB.t;
    vtyp : 'v typ;
  }

  let open_ ?omode vtyp fn = failwith "unimplemented"

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
    hdb : Tokyo_cabinet.HDB.t;
    ktyp : 'k typ;
    vtyp : 'v typ;
  }

  let open_ ?omode ktyp vtyp fn = failwith "unimplemented"

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
