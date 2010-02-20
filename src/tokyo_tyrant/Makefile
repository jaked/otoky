# based on the Cryptokit Makefile

TOKYO_INCLUDE=/usr/local/include
TOKYO_LIBDIR=/usr/local/lib
TOKYO_LIBS=-ltokyotyrant

CFLAGS=-O -I$(TOKYO_INCLUDE)

COMPFLAGS=-package tokyo_common

OCAMLRUN=ocamlrun
OCAMLC=ocamlfind ocamlc -g
OCAMLOPT=ocamlfind ocamlopt
OCAMLDEP=ocamldep
MKLIB=ocamlmklib
OCAMLDOC=ocamldoc

C_OBJS=\
  tokyo_tyrant_stubs.o

CAML_OBJS=\
  tokyo_tyrant.cmo

all: libtokyo_tyrant.a tokyo_tyrant.cmi tokyo_tyrant.cma tokyo_tyrant.cmxa

libtokyo_tyrant.a: $(C_OBJS)
	$(MKLIB) -o tokyo_tyrant $(C_OBJS) -L$(TOKYO_LIBDIR) $(TOKYO_LIBS)

tokyo_tyrant.cma: $(CAML_OBJS)
	$(MKLIB) -o tokyo_tyrant $(CAML_OBJS) -L$(TOKYO_LIBDIR) $(TOKYO_LIBS)

tokyo_tyrant.cmxa: $(CAML_OBJS:.cmo=.cmx)
	$(MKLIB) -o tokyo_tyrant $(CAML_OBJS:.cmo=.cmx) -L$(TOKYO_LIBDIR) $(TOKYO_LIBS)

install:
	ocamlfind install tokyo_tyrant META *.cmi *.mli *.cma *.cmxa *.a *.so

uninstall:
	ocamlfind remove tokyo_tyrant

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
