-include ../../Makefile.conf

ifeq ($(ENABLE_BIN_PROT),1)
BIN_PROT_LIBS=otoky_bin_prot.cmo otoky_bin_prot.cmx
BIN_PROT_FILES=\
otoky_bin_prot.o \
otoky_bin_prot.mli otoky_bin_prot.cmi
endif

LIBS=\
otoky.cma otoky.cmxa \
$(BIN_PROT_LIBS)

FILES=\
$(LIBS) \
otoky.a \
otoky_type.mli otoky_type.cmi \
otoky_bdb.mli otoky_bdb.cmi \
otoky_fdb.mli otoky_fdb.cmi \
otoky_hdb.mli otoky_hdb.cmi \
$(BIN_PROT_FILES)

BFILES=$(addprefix _build/,$(FILES))

PACKAGE=otoky

INSTALL=META $(BFILES)

all: myocamlbuild.ml
	OCAMLPATH=`pwd`/../../stage \
	ocamlbuild $(LIBS)

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
