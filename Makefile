.PHONY: clean all coq test tests examples tutorial hoare_example install uninstall depgraph for-dune dune-build

COQPATHFILE=$(wildcard _CoqPath)

build: coq

# Removes a lot of warnings from dune complaining that $HOME is undefined.
HOME ?= `pwd`
export HOME

dune-build:
	dune build -p coq-itree
	dune build @install

include common.mk

all:
	# Build the library before tests
	$(MAKE) coq
	$(MAKE) test
	$(MAKE) hoare_example

install: Makefile.coq coq
	$(MAKE) -f $< $@

uninstall: Makefile.coq
	$(MAKE) -f $< $@

test: examples tests

tests:
	$(MAKE) -C tests
	$(MAKE) -C tutorial test

examples:
	$(MAKE) -C examples

tutorial:
	$(MAKE) -C tutorial

hoare_example:
	$(MAKE) -C hoare_example


clean: clean-coq
	$(RM) _CoqProject
	$(MAKE) -C tests clean
	$(MAKE) -C examples clean
	$(MAKE) -C tutorial clean
	$(MAKE) -C hoare_example clean
	rm -Rf _build || true

_CoqProject: $(COQPATHFILE) _CoqConfig Makefile
	@ echo "# Generating _CoqProject"
	@ rm -f _CoqProject
	@ echo "# THIS IS AN AUTOMATICALLY GENERATED FILE" >> _CoqProject
	@ echo "# PLEASE EDIT _CoqConfig INSTEAD" >> _CoqProject
	@ echo >> _CoqProject
ifneq ("$(COQPATHFILE)","")
	@ echo "# including: _CoqPath"
	@ cat _CoqPath >> _CoqProject
	@ echo >> _CoqProject
endif
	@ echo "# including: _CoqConfig"
	@ cat _CoqConfig >> _CoqProject

COQDEP=coqdep
DEPS_DOT=deps.dot
DEPS_OUT=deps.jpg

depgraph:
	$(COQDEP) -dumpgraph $(DEPS_DOT) $(shell cat _CoqConfig) > /dev/null 2>&1
	sed 's%\("theories/\([^"]*\)/\([^"/]*\)"\[label="\)%\1\2/\\n%' -i $(DEPS_DOT)
	dot $(DEPS_DOT) -Tjpg -o$(DEPS_OUT)

