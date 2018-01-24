SUBDIRS := $(wildcard tests/*)
CLEANDIRS := $(wildcard tests/*)
SUBMAKEFILES := $(shell find ./tests/* -name Makefile)
DIRS2RUNMAKECHECK := $(addprefix checkdir-,${SUBMAKEFILES})

batcheck: ${DIRS2RUNMAKECHECK}

checkdir-%:
	make -C $(dir $(patsubst checkdir-,,$@)) batcheck

clean: $(CLEANDIRS)
$(CLEANDIRS):
	$(MAKE) -C $@ clean
.PHONY: batcheck $(SUBDIRS)
.PHONY: clean $(CLEANDIRS)
