open Tokyo_common
open Tokyo_cabinet

module Type = Otoky_type

module FDB_raw = FDB.Fun (Cstr_cstr)

type 'v t = {
  fdb : FDB.t;
  vtype : 'v Type.t;
  mutable width : int32;
}

let to_raw_key k func =
  match k with
    | _ when k = FDB.id_max || k = FDB.id_next -> k
    | _ when k = FDB.id_min || k = FDB.id_prev || k = 0L->
        (* we can't easily support min or prev since we take the 1L slot *)
        raise (Error (Einvalid, func, "invalid operation"))
    | _ -> Int64.succ k

let of_raw_key k = Int64.pred k

let marshall t v func =
  let (_, len) as vm = t.vtype.Type.marshall v in
  if Int32.of_int len > t.width
  then raise (Error (Einvalid, func, "marshalled value exceeds width"));
  vm

let check_width vtype width =
  if width < Int32.of_int (String.length (Type.type_desc_hash vtype))
  then raise (Error (Einvalid, "open_", "width too small"))

let open_ ?omode ?width vtype fn =
  let fdb = FDB.new_ () in
  begin match width with
    | None -> ()
    | Some width ->
        check_width vtype width;
        FDB.tune fdb ~width ()
  end;
  FDB.open_ fdb ?omode fn;
  let width = FDB.width fdb in
  let hash = Type.type_desc_hash vtype in
  begin try
    if hash <> FDB.get fdb 1L
    then begin
      FDB.close fdb;
      raise (Error (Einvalid, "open_", "bad type_desc hash"))
    end
  with Error (Enorec, _, _) ->
    (* XXX maybe should check that this is a fresh db? *)
    FDB.put fdb 1L hash;
  end;
  {
    fdb = fdb;
    vtype = vtype;
    width = width;
  }


let close t = FDB.close t.fdb
let copy t fn = FDB.copy t.fdb fn
let fsiz t = FDB.fsiz t.fdb

let get t k =
  let cstr = FDB_raw.get t.fdb (to_raw_key k "get") in
  try
    let v = t.vtype.Type.unmarshall cstr in
    Cstr.del cstr;
    v
  with e -> Cstr.del cstr; raise e

let iterinit t =
  FDB.iterinit t.fdb;
  ignore (FDB.iternext t.fdb)

let iternext t =
  of_raw_key (FDB.iternext t.fdb)

let optimize t ?width ?limsiz () =
  (* XXX maybe should not be able to shrink the width. or we should check width of every record? *)
  FDB.optimize t.fdb ?width ?limsiz ();
  match width with
    | None -> ()
    | Some width ->
        check_width t.vtype width;
        t.width <- width

let out t k =
  FDB.out t.fdb (to_raw_key k "out")

let path t = FDB.path t.fdb

let put t k v =
  FDB_raw.put t.fdb (to_raw_key k "put") (marshall t v "put")

let putkeep t k v =
  FDB_raw.putkeep t.fdb (to_raw_key k "putkeep") (marshall t v "putkeep")

let range t ?lower ?upper ?max () =
  let lower = match lower with None -> Some 2L | Some k -> Some (to_raw_key k "range") in
  let upper = match upper with None -> None | Some k -> Some (to_raw_key k "range") in
  let range = FDB.range t.fdb ?lower ?upper ?max () in
  Array.iteri (fun i k -> range.(i) <- of_raw_key k) range;
  range

let rnum t = FDB.rnum t.fdb
let sync t = FDB.sync t.fdb
let tranabort t = FDB.tranabort t.fdb
let tranbegin t = FDB.tranbegin t.fdb
let trancommit t = FDB.trancommit t.fdb

let tune t ?width ?limsiz () =
  begin match width with
    | None -> ()
    | Some width -> check_width t.vtype width
  end;
  FDB.tune t.fdb ?width ?limsiz ()

let vanish t = FDB.vanish t.fdb

let vsiz t k = FDB.vsiz t.fdb (to_raw_key k "vsiz")
