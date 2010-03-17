-include ../../Makefile.conf

# based on the Cryptokit Makefile

TC_LIBS=-ltokyocabinet

CFLAGS=-O -I$(TC_INCLUDE)

COMPFLAGS=-package tokyo_common

OCAMLRUN=ocamlrun
OCAMLC=OCAMLFIND_LDCONF=`pwd`/../../stage/ld.conf OCAMLPATH=`pwd`/../../stage ocamlfind ocamlc
OCAMLOPT=OCAMLFIND_LDCONF=`pwd`/../../stage/ld.conf OCAMLPATH=`pwd`/../../stage ocamlfind ocamlopt
OCAMLDEP=ocamldep
MKLIB=ocamlmklib
OCAMLDOC=ocamldoc

C_OBJS=tokyo_cabinet_stubs.o

CAML_OBJS=tokyo_cabinet.cmo

PACKAGE=tokyo_cabinet

INSTALL=META *.cmi *.mli *.cma *.cmxa *.a *.so

all: libtokyo_cabinet.a tokyo_cabinet.cmi tokyo_cabinet.cma tokyo_cabinet.cmxa
	ocamlfind remove -ldconf ../../stage/ld.conf -destdir ../../stage $(PACKAGE)
	ocamlfind install -ldconf ../../stage/ld.conf -destdir ../../stage $(PACKAGE) $(INSTALL)

libtokyo_cabinet.a: $(C_OBJS)
	$(MKLIB) -o tokyo_cabinet $(C_OBJS) -L$(TC_LIBDIR) $(TC_LIBS)

tokyo_cabinet.cma: $(CAML_OBJS)
	$(MKLIB) -o tokyo_cabinet $(CAML_OBJS) -L$(TC_LIBDIR) $(TC_LIBS)

tokyo_cabinet.cmxa: $(CAML_OBJS:.cmo=.cmx)
	$(MKLIB) -o tokyo_cabinet $(CAML_OBJS:.cmo=.cmx) -L$(TC_LIBDIR) $(TC_LIBS)

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
