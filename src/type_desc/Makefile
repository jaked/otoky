-include ../../Makefile.conf

FILES=\
type_desc.cma type_desc.cmxa type_desc.a \
type_desc.mli type_desc.cmi \
pa_type_desc.cmo \

BFILES=$(addprefix _build/,$(FILES))

all: myocamlbuild.ml
	ocamlbuild type_desc.cma type_desc.cmxa pa_type_desc.cmo

install:
	ocamlfind install type_desc META $(BFILES)

uninstall:
	ocamlfind remove type_desc

clean:
	ocamlbuild -clean
	rm -f myocamlbuild.ml

myocamlbuild.ml:
	ln -s ../../tools/myocamlbuild.ml .
