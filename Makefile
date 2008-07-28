# Hacky makefile to compile everything and run the tests in some kind of sane order.
# V=--verbose for verbose tests.

CFLAGS=-g -Wall -Wstrict-prototypes -Wold-style-definition -Wmissing-prototypes -Wmissing-declarations -Werror -Iccan -I.

ALL=$(patsubst ccan/%/test, %, $(wildcard ccan/*/test))
ALL_DIRS=$(patsubst %, ccan/%, $(ALL))
ALL_DEPENDS=$(patsubst %, ccan/%/.depends, $(ALL))
ALL_LIBS=$(patsubst %, ccan/lib%.a, $(ALL))

test: $(ALL_DIRS:%=test-%)

distclean: clean
	rm -f */_info
	rm -f $(ALL_DEPENDS)

$(ALL_DEPENDS): $(ALL_DIRS:=/_info)

$(ALL_DEPENDS): %/.depends: tools/ccan_depends
	tools/ccan_depends $* > $@ || ( rm -f $@; exit 1 )

foo:
	echo $(ALL_LIBS)

$(ALL_LIBS):
	$(AR) r $@ $^

test-ccan/%: tools/run_tests ccan/lib%.a
	@echo Testing $*...
	@if tools/run_tests $(V) ccan/$* | grep ^'not ok'; then exit 1; else exit 0; fi

ccanlint: tools/ccanlint/ccanlint

clean: tools-clean
	$(RM) `find . -name '*.o'` `find . -name '.depends'` `find . -name '*.a'`
	$(RM) inter-depends lib-depends test-depends

inter-depends: $(ALL_DEPENDS)
	for f in $(ALL_DEPENDS); do echo test-ccan/`basename \`dirname $$f\``: `sed -n 's,ccan/\(.*\),ccan/lib\1.a,p' < $$f`; done > $@

test-depends: $(ALL_DEPENDS)
	for f in $(ALL_DEPENDS); do echo test-ccan/`basename \`dirname $$f\``: `sed -n 's,ccan/\(.*\),test-ccan/\1,p' < $$f`; done > $@

lib-depends: $(foreach D,$(ALL),$(wildcard $D/*.[ch]))
	for c in $(ALL); do echo ccan/lib$$c.a: `ls ccan/$$c/*.c | grep -v /_info.c | sed 's/.c$$/.o/'`; done > $@

include tools/Makefile
-include inter-depends
-include test-depends
-include lib-depends
