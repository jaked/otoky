-include ../../Makefile.conf

FILES=\
type_desc.cma type_desc.cmxa type_desc.a \
type_desc.mli type_desc.cmi \
pa_type_desc.cmo \

BFILES=$(addprefix _build/,$(FILES))

PACKAGE=type_desc

INSTALL=META $(BFILES)

all: myocamlbuild.ml
	ocamlbuild type_desc.cma type_desc.cmxa pa_type_desc.cmo
	ocamlfind remove -destdir ../../stage $(PACKAGE)
	ocamlfind install -destdir ../../stage $(PACKAGE) $(INSTALL)

doc:
	OCAMLPATH=`pwd`/../../stage \
	ocamlbuild -no-links doc.docdir/index.html

install:
	ocamlfind install $(PACKAGE) $(INSTALL)

uninstall:
	ocamlfind remove $(PACKAGE)

clean:
	ocamlbuild -clean
	rm -f myocamlbuild.ml

myocamlbuild.ml:
	ln -s ../../tools/myocamlbuild.ml .
