(*
  The goal here is to come up with a type descriptor that can be
  marshalled, in order to check if marshalled data is compatible with
  the program using it. The equality on descriptors is more coarse
  than ordinary OCaml type equality; we make no attempt to handle
  abstraction or generativity.

  Extensions in polymorphic variants are represented explicitly so the
  descriptors can be built independently and composed. However whether
  a polymorphic variant is built by extension or not does not affect
  its type so we need to be careful with the equality.

  Descriptors are of ground types only; polymorphic types are
  represented by functions from a descriptor for each type argument to
  a descriptor.

  For bundles of recursive types we replace occurrences of the type(s)
  being defined with `Var. To ensure that `Vars refer to the right
  types, a bundle is represented by `Bundle, and individual types in
  the bundle by `Project.

  Compare to Xdr.xdr_type_term in Ocamlnet, and see also the comment
  "this is kind of hairy [...]" in orpc/src/generator gen_aux.ml.

  XXX
  each type in a bundle depends on each other type, whether or not it refers to it
    could trim out the parts it doesn't refer to
  type depends on its declared name in `Bundle / `Var
    could use indexes instead (and depend on the order within a bundle)
*)

type s = [
| `Unit
| `Int
| `Int32
| `Int64
| `Float
| `Bool
| `Char
| `String
| `Tuple of s list
| `Sum of (string * s list) list
| `Record of (string * s) list
| `Polyvar of [ `Tag of string * s option | `Extend of s (* = `Polyvar *) ] list
| `List of s
| `Option of s
| `Array of s
| `Hashtbl of s * s
| `Var of string
| `Bundle of (string * s) list
| `Project of string * s (* = `Bundle *)
]

let norm_polyvar arms =
  let rec flatten tags arms =
    List.fold_left
      (fun tags -> function
         | `Tag (tag, s) -> (tag, s)::tags
         | `Extend (`Polyvar arms) -> flatten tags arms
         | _ -> assert false)
      tags arms in
  List.sort
    (fun (tag1, _) (tag2, _) -> compare tag1 tag2)
    (flatten [] arms)

let rec equal s1 s2 =
  match s1, s2 with
    | `Unit, `Unit -> true
    | `Int, `Int -> true
    | `Int32, `Int32 -> true
    | `Int64, `Int64 -> true
    | `Float, `Float -> true
    | `Bool, `Bool -> true
    | `Char, `Char -> true
    | `String, `String -> true

    | `Tuple parts1, `Tuple parts2 ->
        List.for_all2 equal parts1 parts2

    | `Sum arms1, `Sum arms2 ->
        (* order matters *) (* XXX check bin_prot *)
        List.for_all2
          (fun (tag1, parts1) (tag2, parts2) -> tag1 = tag2 && List.for_all2 equal parts1 parts2)
          arms1 arms2

    | `Record fields1, `Record fields2 ->
        List.for_all2
          (fun (name1, s1) (name2, s2) -> name1 = name2 && equal s1 s2)
          fields1 fields2

    | `Polyvar arms1, `Polyvar arms2 ->
        (* ordered by tag name *) (* XXX check bin_prot *)
        List.for_all2
          (fun (tag1, s1) (tag2, s2) ->
            tag1 = tag2 &&
              match s1, s2 with
                | None, None -> true
                | Some s1, Some s2 -> equal s1 s2
                | _ -> false)
          (norm_polyvar arms1) (norm_polyvar arms2)

    | `List s1, `List s2 -> equal s1 s2
    | `Option s1, `Option s2 -> equal s1 s2
    | `Array s1, `Array s2 -> equal s1 s2
    | `Hashtbl (s1, t1), `Hashtbl (s2, t2) -> equal s1 s2 && equal t1 t2

    | `Var v1, `Var v2 -> v1 = v2

    | `Bundle types1, `Bundle types2 ->
        (* types are sorted by name at construction *)
        List.for_all2
          (fun (name1, s1) (name2, s2) -> name1 = name2 && equal s1 s2)
          types1 types2

    | `Project (name1, s1), `Project (name2, s2) ->
        name1 = name2 && equal s1 s2

    | _ -> false

type 'a t = s

let hide s = s
let show t = t

(* to_string s1 = to_string s2 <=> equal s1 s2 *)
let to_string s =
  let b = Buffer.create 256 in
  let add = Buffer.add_string b in
  let rec to_s : s -> unit = function
    | `Unit -> add "unit"
    | `Int -> add "int"
    | `Int32 -> add "int32"
    | `Int64 -> add "int64"
    | `Float -> add "float"
    | `Bool -> add "bool"
    | `Char -> add "char"
    | `String -> add "string"
    | `Tuple parts ->
	add "(tuple";
	List.iter (fun s -> add " "; to_s s) parts;
	add ")"
    | `Sum arms ->
	add "(sum";
	List.iter
	  (fun (tag, parts) ->
	     add " ";
	     match parts with
	       | [] -> add tag;
	       | _ -> add "("; add tag; List.iter (fun s -> add " "; to_s s) parts; add ")")
	  arms;
	add ")";
    | `Record fields ->
	add "(record";
	List.iter (fun (name, s) -> add " ("; add name; add " "; to_s s) fields;
	add ")";
    | `Polyvar arms ->
	add "(polyvar";
	List.iter
	  (fun (tag, so) ->
	     add " ";
	     match so with
	       | None -> add tag;
	       | Some s -> add "("; add tag; to_s s; add ")")
	  (norm_polyvar arms);
	add ")";
    | `List s -> add "(list "; to_s s; add ")"
    | `Option s -> add "(option "; to_s s; add ")"
    | `Array s -> add "(array "; to_s s; add ")"
    | `Hashtbl (k, v) -> add "(hashtbl "; to_s k; add " "; to_s v; add ")"
    | `Var s -> add "(var "; add s; add ")"
    | `Bundle parts ->
	add "(bundle";
	List.iter (fun (name, s) -> add " ("; add name; add " "; to_s s; add ")") parts;
	add ")";
    | `Project (name, s) ->
	add "(project "; add name; add " "; to_s s; add ")" in
  to_s s;
  Buffer.contents b
