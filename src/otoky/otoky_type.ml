open Tokyo_common

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

let type_desc_hash t = Digest.string (Type_desc.to_string t.type_desc)
