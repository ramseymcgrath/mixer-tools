SUBMAKEFILES := $(shell find tests/ -name Makefile)
DIRS2RUNMAKECHECK := $(addprefix checkdir-,${SUBMAKEFILES})
DIRS2RUNMAKECLEAN := $(addprefix clean-,${SUBMAKEFILES})

batcheck: ${DIRS2RUNMAKECHECK}

${DIRS2RUNMAKECHECK}: checkdir-%:
	make -C $(dir $(subst checkdir-,,$@)) check

clean: $(DIRS2RUNMAKECLEAN)
${DIRS2RUNMAKECLEAN}: clean-%:
	make -C $(dir $(subst checkdir-,,$@)) clean
.PHONY: batcheck
.PHONY: clean
.PHONY: ${DIRS2RUNMAKECHECK}
.PHONY: ${DIRS2RUNMAKECLEAN}
