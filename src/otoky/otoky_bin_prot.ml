open Tokyo_common

let marshall bin v =
  let len = bin.Bin_prot.Type_class.writer.Bin_prot.Type_class.size v in
  let buf = Bin_prot.Common.create_buf len in
  ignore (bin.Bin_prot.Type_class.writer.Bin_prot.Type_class.write buf ~pos:0 v);
  Cstr.of_bigarray buf

let unmarshall bin cstr =
  let buf = Cstr.to_bigarray cstr in
  bin.Bin_prot.Type_class.reader.Bin_prot.Type_class.read buf ~pos_ref:(ref 0)
