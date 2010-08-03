open Camlp4.PreCast
open Pa_type_conv

let _loc = Loc.ghost

let type_desc_ id = "type_desc_" ^ id

(* arrows t1..tn t => t1 -> .. -> tn -> t *)
let arrows ts t = List.fold_right (fun t a -> <:ctyp< $t$ -> $a$ >>)  ts t

(* tapps t1..tn t => (t1, .., tn) t *)
let tapps ts t = List.fold_left (fun a t -> <:ctyp< $a$ $t$ >>) t ts

(* funs p1..pn e => fun p1 .. pn -> e *)
let funs ps e = List.fold_right (fun p e -> <:expr< fun $p$ -> $e$ >>) ps e

let funs_ids vs e = funs (List.map (fun v -> <:patt< $lid:v$ >>) vs) e

(* apps e e1..en = e e1 .. en *)
let apps e es = List.fold_left (fun e e' -> <:expr< $e$ $e'$ >>) e es

let rec list_of_exprs = function
  | [] -> <:expr< [] >>
  | h::t -> <:expr< [ $h$ :: $list_of_exprs t$ ] >>

let next_bundle_id =
  let bundle = ref (-1) in
  fun () ->
    incr bundle;
    "__type_desc_bundle_" ^ string_of_int (!bundle)

let type_desc bound_ids _loc t =
  let rec td = function
    | <:ctyp< unit >> -> <:expr< Type_desc.Unit >>
    | <:ctyp< int >> -> <:expr< Type_desc.Int >>
    | <:ctyp< int32 >> -> <:expr< Type_desc.Int32 >>
    | <:ctyp< int64 >> -> <:expr< Type_desc.Int64 >>
    | <:ctyp< float >> -> <:expr< Type_desc.Float >>
    | <:ctyp< bool >> -> <:expr< Type_desc.Bool >>
    | <:ctyp< char >> -> <:expr< Type_desc.Char >>
    | <:ctyp< string >> -> <:expr< Type_desc.String >>

    | Ast.TyTup (_, t) ->
        let parts = List.map td (Ast.list_of_ctyp t []) in
        <:expr< Type_desc.Tuple ($list_of_exprs parts$) >>

    | <:ctyp< { $t$ } >> ->
        let fields =
          List.map
            (function
              | <:ctyp< $lid:id$ : mutable $t$ >>
              | <:ctyp< $lid:id$ : $t$ >> -> <:expr< ($`str:id$, $td t$) >>
              | _ -> assert false)
            (Ast.list_of_ctyp t []) in
        <:expr< Type_desc.Record ($list_of_exprs fields$) >>

    | Ast.TySum (_, t) ->
        let arms =
          List.map
            (function
              | <:ctyp< $uid:id$ >> -> <:expr< ($`str:id$, []) >>
              | <:ctyp< $uid:id$ of $t$ >> ->
                  let parts = List.map td (Ast.list_of_ctyp t []) in
                  <:expr< ($`str:id$, $list_of_exprs parts$) >>
              | _ -> assert false)
            (Ast.list_of_ctyp t []) in
        <:expr< Type_desc.Sum ($list_of_exprs arms$) >>

    | Ast.TyVrnEq (_, t) ->
        let arms =
          List.map
            (function
              | <:ctyp< `$id$ >> -> <:expr< Type_desc.Tag ($`str:id$, None) >>
              | <:ctyp< `$id$ of $t$ >> -> <:expr< Type_desc.Tag ($`str:id$, Some ($td t$)) >>
              | <:ctyp< $id:id$ >> -> <:expr< Type_desc.Extend $td <:ctyp< $id:id$ >>$ >>
              | _ -> assert false)
          (Ast.list_of_ctyp t []) in
        <:expr< Type_desc.Polyvar ($list_of_exprs arms$) >>

    | <:ctyp< list $t$ >> -> <:expr< Type_desc.List $td t$ >>
    | <:ctyp< option $t$ >> -> <:expr< Type_desc.Option $td t$ >>
    | <:ctyp< array $t$ >> -> <:expr< Type_desc.Array $td t$ >>
    | <:ctyp< Hashtblt.t $t1$ $t2$ >> -> <:expr< Type_desc.Hashtbl ($td t1$, $td t2$) >>
    | <:ctyp< ref $t$ >> -> td t

    | <:ctyp< '$v$ >> -> <:expr< $lid:v$ >>

    | <:ctyp< $id:id$ >> ->
        let ids = Ast.list_of_ident id [] in
        begin match List.rev ids with
          | [ <:ident< $lid:id$ >> ] when List.mem_assoc id bound_ids ->
              <:expr< Type_desc.Var $`int:List.assoc id bound_ids$ >>
          | <:ident< $lid:id$ >>::uids ->
              let ids = List.rev (<:ident< $lid:type_desc_ id$ >>::uids) in
              <:expr< Type_desc.show $id:<:ident< $list:ids$ >>$ >>
          | _ -> assert false
        end

    | <:ctyp< $_$ $_$ >> as t ->
        let rec loop args = function
          | <:ctyp< $t1$ $t2$ >> ->
              let arg = <:expr< Type_desc.hide $td t2$ >> in
              loop (arg :: args) t1
          | t ->
              match td t with
                  (* a reference to a type being defined shouldn't be applied; it's just a tag *)
                | <:expr< Type_desc.Var $_$ >> as e -> e
                  (* we wrap show around an identifier before we know it is applied *)
                | <:expr< Type_desc.show $e$ >> ->
                    <:expr< Type_desc.show $apps e args$ >>
                | _ -> assert false in (* XXX syntax error, raise friendly error *)
        loop [] t

    | _ -> failwith "unimplemented" in
  td t

let gen_str tds =
  let ctyps = Ast.list_of_ctyp tds [] in

  (* assoc of all ids in type bundle to their index in bundle *)
  let ids =
    let rec loop i = function
      | [] -> []
      | (Ast.TyDcl (_, id, _, _, _)) :: t -> (id, i) :: loop (i + 1) t
      | _ -> assert false in
    loop 0 ctyps in

  (* individual type descriptions *)
  let type_descs =
    List.map
      (function
        | Ast.TyDcl (_loc, id, vars, t, []) ->
            let vars = List.map (function <:ctyp< '$v$ >> -> v | _ -> assert false) vars in
            id, vars, type_desc ids _loc t
        | Ast.TyDcl _ -> failwith "type constraints not supported"
        | _ -> assert false)
      ctyps in

  (* all vars in type bundle *)
  let vars =
    List.fold_left
      (fun vars (_, vars', _) ->
        List.fold_left
          (fun vars var -> if List.mem var vars then vars else var::vars)
          vars vars')
      [] type_descs in
  let vars = List.sort compare vars in

  (* bundle abstracted over variables *)
  let bundle_id = next_bundle_id () in
  let bundle =
    <:str_item<
      value $lid:bundle_id$ =
        $funs_ids vars <:expr<
          Type_desc.Bundle ($list_of_exprs (List.map (fun (_, _, s) -> s) type_descs)$)
        >>$
    >> in

  (* projections from bundle, unused variables filled in with dummys *)
  let projects =
    List.map
      (fun (id, vars', _) ->
        let args =
          List.map
            (fun v -> if List.mem v vars' then <:expr< Type_desc.show $lid:v$ >> else <:expr< Type_desc.Unit >>)
            vars in
        let t = tapps (List.map (fun v -> <:ctyp< '$v$ >>) vars') <:ctyp< $lid:id$ >> in
        let ret = <:ctyp< Type_desc.t $t$ >> in
        let targs = List.map (fun v -> <:ctyp< Type_desc.t '$v$ >>) vars' in
        <:str_item<
          value $lid:type_desc_ id$ =
            ($funs_ids
                vars'
                <:expr< Type_desc.hide (Type_desc.Project ($`int:List.assoc id ids$, $apps <:expr< $lid:bundle_id$ >> args$)) >>$ :
              $arrows targs ret$)
        >>)
      type_descs in

  let _loc = Ast.loc_of_ctyp tds in
  <:str_item< $bundle$ ; $list:projects$ >>

let sig_item _loc id vars =
  let t = tapps vars <:ctyp< $lid:id$ >> in
  let ret = <:ctyp< Type_desc.t $t$ >> in
  let args = List.map (fun v -> <:ctyp< Type_desc.t $v$ >>) vars in
  <:sig_item< value $lid:type_desc_ id$ : $arrows args ret$ >>

let gen_sig tds =
  let sig_items =
    List.map
      (function
        | Ast.TyDcl (_loc, id, vars, _, []) -> sig_item _loc id vars
        | Ast.TyDcl _ -> failwith "type constraints not supported"
        | _ -> assert false)
      (Ast.list_of_ctyp tds []) in
  let _loc = Ast.loc_of_ctyp tds in
  <:sig_item< $list:sig_items$ >>

;;

Pa_type_conv.add_generator "type_desc" gen_str;
Pa_type_conv.add_sig_generator "type_desc" gen_sig;
