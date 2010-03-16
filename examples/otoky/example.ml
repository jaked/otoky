open Tokyo_common
open Tokyo_cabinet


type k = {
  foo : string;
} with type_desc

type v = {
  bar : string;
} with type_desc

let ktype =
  let type_desc = type_desc_k in
  let marshall { foo = foo } = (foo, String.length foo) in
  let unmarshall cstr = { foo = Cstr.copy cstr } in
  Otoky_type.make ~type_desc ~marshall ~unmarshall ~compare

let vtype =
  let type_desc = type_desc_v in
  let marshall { bar = bar } = (bar, String.length bar) in
  let unmarshall cstr = { bar = Cstr.copy cstr } in
  Otoky_type.make ~type_desc ~marshall ~unmarshall ~compare

let example () =
  let fn = Filename.temp_file "foo" "bar" in
  let bdb = Otoky_bdb.open_ ~omode:[Oreader;Owriter;Ocreat] ktype vtype fn in

  Otoky_bdb.put bdb { foo = "foo" } { bar = "bar" };
  Otoky_bdb.put bdb { foo = "bar" } { bar = "baz" };

  let { bar = bar } = Otoky_bdb.get bdb { foo = "bar" } in
  prerr_endline bar;

  Otoky_bdb.close bdb;
  Unix.unlink fn

;;

example ()
