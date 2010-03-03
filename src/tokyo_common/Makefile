-include ../../Makefile.conf

# based on the Cryptokit Makefile

TOKYO_INCLUDE=/usr/local/include
TOKYO_LIBDIR=/usr/local/lib
TOKYO_LIBS=-ltokyocabinet

CFLAGS=-O -I$(TOKYO_INCLUDE)

OCAMLRUN=ocamlrun
OCAMLC=ocamlc
OCAMLOPT=ocamlopt
OCAMLDEP=ocamldep
MKLIB=ocamlmklib
OCAMLDOC=ocamldoc

C_OBJS=tokyo_common_stubs.o

CAML_OBJS=tokyo_common.cmo

PACKAGE=tokyo_common

INSTALL=META *.cmi *.mli *.cma *.cmxa *.a *.so

all: libtokyo_common.a tokyo_common.cmi tokyo_common.cma tokyo_common.cmxa
	ocamlfind remove -ldconf ../../stage/ld.conf -destdir ../../stage $(PACKAGE)
	ocamlfind install -ldconf ../../stage/ld.conf -destdir ../../stage $(PACKAGE) $(INSTALL)

libtokyo_common.a: $(C_OBJS)
	$(MKLIB) -o tokyo_common $(C_OBJS) -L$(TOKYO_LIBDIR) $(TOKYO_LIBS)

tokyo_common.cma: $(CAML_OBJS)
	$(MKLIB) -o tokyo_common $(CAML_OBJS) -L$(TOKYO_LIBDIR) $(TOKYO_LIBS)

tokyo_common.cmxa: $(CAML_OBJS:.cmo=.cmx)
	$(MKLIB) -o tokyo_common $(CAML_OBJS:.cmo=.cmx) -L$(TOKYO_LIBDIR) $(TOKYO_LIBS)

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
