-include ../../Makefile.conf

FILES=\
otoky.cma otoky.cmxa otoky.a \
otoky_tc.mli otoky_tc.cmi \

BFILES=$(addprefix _build/,$(FILES))

PACKAGE=otoky

INSTALL=META $(BFILES)

all: myocamlbuild.ml
	OCAMLPATH=`pwd`/../../stage \
	ocamlbuild otoky.cma otoky.cmxa

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
