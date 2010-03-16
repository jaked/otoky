open Tokyo_cabinet

let example () =
  let bdb = BDB.new_ () in
  let fn = Filename.temp_file "foo" "bar" in
  BDB.open_ bdb ~omode:[Oreader;Owriter;Ocreat] fn;

  BDB.put bdb "foo" "bar";
  BDB.put bdb "bar" "baz";
  BDB.put bdb "baz" "quux";

  List.iter prerr_endline (BDB.range bdb ());
  List.iter prerr_endline (BDB.fwmkeys bdb "ba");

  (try BDB.putkeep bdb "baz" "xyzzy" with Error(Ekeep, _, _) -> prerr_endline "exists");

  BDB.putcat bdb "bar" "baz";
  prerr_endline (BDB.get bdb "bar");

  BDB.tranbegin bdb;
  BDB.put bdb "plugh" "xyzzy";
  BDB.tranabort bdb;
  (try ignore (BDB.get bdb "plugh") with Error(Enorec, _, _) -> prerr_endline "doesn't exist");

  BDB.close bdb;
  Unix.unlink fn

;;

example ()
