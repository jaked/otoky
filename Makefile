# based on the Cryptokit Makefile

TOKYO_INCLUDE=/usr/local/include
TOKYO_LIBDIR=/usr/local/lib
TOKYO_LIBS=-ltokyocabinet

CFLAGS=-O -I$(TOKYO_INCLUDE)

OCAMLRUN=ocamlrun
OCAMLC=ocamlc -g
OCAMLOPT=ocamlopt
OCAMLDEP=ocamldep
MKLIB=ocamlmklib
OCAMLDOC=ocamldoc

C_OBJS=\
  stubs-cabinet.o

CAML_OBJS=\
  tokyo_cabinet.cmo

all: libotoky.a tokyo_cabinet.cmi otoky.cma

opt: libotoky.a tokyo_cabinet.cmi otoky.cmxa

libotoky.a: $(C_OBJS)
	$(MKLIB) -o otoky $(C_OBJS) -L$(TOKYO_LIBDIR) $(TOKYO_LIBS)

otoky.cma: $(CAML_OBJS)
	$(MKLIB) -o otoky $(CAML_OBJS) -L$(TOKYO_LIBDIR) $(TOKYO_LIBS)

otoky.cmxa: $(CAML_OBJS:.cmo=.cmx)
	$(MKLIB) -o otoky $(CAML_OBJS:.cmo=.cmx) -L$(TOKYO_LIBDIR) $(TOKYO_LIBS)

install:
	ocamlfind install otoky META *.cmi *.mli *.cma *.cmxa *.a *.so

uninstall:
	ocamlfind remove otoky

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
