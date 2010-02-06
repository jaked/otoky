-include ../../Makefile.conf

FILES=\
type_hash.cma type_hash.cmxa type_hash.a \
type_hash.mli type_hash.cmi \
type_hash_make.mli type_hash_make.cmi \
pa_type_hash.cmo \

BFILES=$(addprefix _build/,$(FILES))

all: myocamlbuild.ml
	ocamlbuild type_hash.cma type_hash.cmxa pa_type_hash.cmo

install:
	ocamlfind install type_hash META $(BFILES)

uninstall:
	ocamlfind remove type_hash

clean:
	ocamlbuild -clean
	rm -f myocamlbuild.ml

myocamlbuild.ml:
	ln -s ../../tools/myocamlbuild.ml .
