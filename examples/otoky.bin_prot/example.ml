TYPE_CONV_PATH "Example" (* for bin_io *)

open Tokyo_common
open Tokyo_cabinet

type k = This of string | That of int
  with type_desc, bin_io

type v = Foo | Bar | Baz of string | Quux of float
  with type_desc, bin_io

let ktype =
  let type_desc = type_desc_k in
  let marshall = Otoky_bin_prot.marshall bin_k in
  let unmarshall = Otoky_bin_prot.unmarshall bin_k in
  Otoky_type.make ~type_desc ~marshall ~unmarshall ~compare

let vtype =
  let type_desc = type_desc_v in
  let marshall = Otoky_bin_prot.marshall bin_v in
  let unmarshall = Otoky_bin_prot.unmarshall bin_v in
  Otoky_type.make ~type_desc ~marshall ~unmarshall ~compare

let example () =
  let fn = Filename.temp_file "foo" "bar" in
  let bdb = Otoky_bdb.open_ ~omode:[Oreader;Owriter;Ocreat] ktype vtype fn in

  Otoky_bdb.put bdb (This "foo") Foo;
  Otoky_bdb.put bdb (That 7) (Baz "seven");

  begin match Otoky_bdb.get bdb (That 7) with
    | (Baz s) -> prerr_endline s
    | _ -> assert false;
  end;

  Otoky_bdb.close bdb;
  Unix.unlink fn

;;

example ()
