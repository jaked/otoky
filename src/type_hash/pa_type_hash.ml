open Camlp4.PreCast
open Pa_type_conv

let gen tds =
  let _loc = Ast.loc_of_ctyp tds in
  <:str_item< >>

;;

Pa_type_conv.add_generator "type_hash" gen
