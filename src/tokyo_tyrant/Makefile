-include ../../Makefile.conf

# based on the Cryptokit Makefile

TT_LIBS=-ltokyotyrant

CFLAGS=-O -I$(TT_INCLUDE)

COMPFLAGS=-package tokyo_common

OCAMLRUN=ocamlrun
OCAMLC=OCAMLFIND_LDCONF=`pwd`/../../stage/ld.conf OCAMLPATH=`pwd`/../../stage ocamlfind ocamlc
OCAMLOPT=OCAMLFIND_LDCONF=`pwd`/../../stage/ld.conf OCAMLPATH=`pwd`/../../stage ocamlfind ocamlopt
OCAMLDEP=ocamldep
MKLIB=ocamlmklib
OCAMLDOC=ocamldoc

C_OBJS=tokyo_tyrant_stubs.o

CAML_OBJS=tokyo_tyrant.cmo

PACKAGE=tokyo_tyrant

INSTALL= META *.cmi *.mli *.cma *.cmxa *.a *.so

all: libtokyo_tyrant.a tokyo_tyrant.cmi tokyo_tyrant.cma tokyo_tyrant.cmxa
	ocamlfind remove -ldconf ../../stage/ld.conf -destdir ../../stage $(PACKAGE)
	ocamlfind install -ldconf ../../stage/ld.conf -destdir ../../stage $(PACKAGE) $(INSTALL)

libtokyo_tyrant.a: $(C_OBJS)
	$(MKLIB) -o tokyo_tyrant $(C_OBJS) -L$(TT_LIBDIR) $(TT_LIBS)

tokyo_tyrant.cma: $(CAML_OBJS)
	$(MKLIB) -o tokyo_tyrant $(CAML_OBJS) -L$(TT_LIBDIR) $(TT_LIBS)

tokyo_tyrant.cmxa: $(CAML_OBJS:.cmo=.cmx)
	$(MKLIB) -o tokyo_tyrant $(CAML_OBJS:.cmo=.cmx) -L$(TT_LIBDIR) $(TT_LIBS)

install:
	ocamlfind install $(PACKAGE) $(INSTALL)

uninstall:
	ocamlfind remove $(PACKAGE)

.SUFFIXES: .ml .mli .cmo .cmi .cmx

.mli.cmi:
	$(OCAMLC) -c $(COMPFLAGS) $<

.ml.cmo:
	$(OCAMLC) -c $(COMPFLAGS) $<

.ml.cmx:
	$(OCAMLOPT) -c $(COMPFLAGS) $<

.c.o:
	$(OCAMLC) -c -ccopt "$(CFLAGS)" $<

clean::
	rm -f *.cm* *.o *.a *.so
