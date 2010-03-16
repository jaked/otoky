-include ../Makefile.conf

ifeq ($(ENABLE_BIN_PROT),1)
BIN_PROT_DIR=otoky.bin_prot
endif

DIRS=tokyo_cabinet type_desc otoky $(BIN_PROT_DIR)

all:
	for dir in $(DIRS); do \
		$(MAKE) -C $$dir all || exit; \
	done

clean:
	for dir in $(DIRS); do \
		$(MAKE) -C $$dir clean || exit; \
	done
