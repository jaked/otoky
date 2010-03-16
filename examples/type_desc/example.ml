module A =
struct
  type 'a t = Foo | Bar of 'a
  and 'a u = Baz of string | Quux of 'a t
    with type_desc

  type v = (int * int) t
    with type_desc
end

module B =
struct
  type 'a t2 = Foo | Bar of 'a
  and 'a u2 = Baz of string | Quux of 'a t2
    with type_desc

  type v2 = (int * int) t2
    with type_desc
end

;;

(* type equality is structural, names don't count, no generativity *)
assert (Type_desc.equal A.type_desc_v B.type_desc_v2);
