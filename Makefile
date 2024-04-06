
-include config.mak

PG_CONFIG ?= pg_config
PG_INCDIR = $(shell $(PG_CONFIG) --includedir)
PG_LIBDIR = $(shell $(PG_CONFIG) --libdir)
RST2MAN = rst2man

bin_PROGRAMS = pgqd
man_MANS = pgqd.1

pgqd_SOURCES = src/pgqd.c src/maint.c src/ticker.c src/retry.c \
	       src/pgsocket.c src/pgsocket.h \
	       src/pgqd.h
nodist_pgqd_SOURCES = pgqd.ini.h
pgqd_CPPFLAGS = -I$(PG_INCDIR) -Isrc -I.
pgqd_LDFLAGS = -L$(PG_LIBDIR)
pgqd_LIBS = -lpq -lm

pgqd_EMBED_LIBUSUAL = 1
USUAL_DIR = lib
AM_FEATURES = libusual

EXTRA_DIST = pgqd.ini autogen.sh configure.ac Makefile \
	     README.rst NEWS.rst tests/test.sh \
	     lib/find_modules.sh \
	     lib/mk/antimake.mk lib/mk/amext-libusual.mk \
	     lib/mk/install-sh lib/mk/std-autogen.sh \
	     config.mak.in lib/usual/config.h.in \
	     lib/m4/antimake.m4 \
	     lib/m4/ax_pthread.m4 \
	     lib/m4/usual.m4 \
	     configure config.sub config.guess install-sh
CLEANFILES = pgqd.ini.h

CONFIG_H = $(USUAL_DIR)/lib/usual/config.h

include $(USUAL_DIR)/mk/antimake.mk

pgqd.ini.h: pgqd.ini
	sed -f etc/quote-lines.sed $< > $@

install: install-conf
install-conf:
	mkdir -p '$(DESTDIR)$(docdir)/conf'
	$(INSTALL) -m 644 pgqd.ini '$(DESTDIR)$(docdir)/conf/pgqd.ini.templ'

tags:
	ctags src/*.[ch] lib/usual/*.[ch]

configure:
	./autogen.sh

#config.mak: configure
#	./configure

*.o: $(CONFIG_H)

$(CONFIG_H):
	$(error Please run ./configure first)

xclean: clean
	rm -f config.mak config.guess config.sub config.log config.sub config.status
	rm -f configure install-sh lib/usual/config.h

pgqd.1: README.rst
	$(RST2MAN) $< > $@

citest: check

check:
	./tests/test.sh

# PACKAGE_VERSION
VERSION = $(shell ./configure --version | head -n 1 | sed -e 's/.* //')
RXVERSION = $(shell echo $(VERSION) | sed 's/\./[.]/g')
NEWS = NEWS.rst
TAG = v$(VERSION)

checkver:
	@echo "Checking version"
	@test -f configure || { echo "need ./configure"; exit 1; }
	@grep -q '^pgqd $(RXVERSION)\b' $(NEWS) \
	|| { echo "Version '$(VERSION)' not in $(NEWS)"; exit 1; }
	@echo "Checking git repo"
	@git diff --stat --exit-code || { echo "ERROR: Unclean repo"; exit 1; }

release: checkver
	git tag $(TAG)
	git push github $(TAG):$(TAG)

unrelease:
	git push github :$(TAG)
	git tag -d $(TAG)

shownote:
	awk -v VER="$(VERSION)" -f etc/note.awk $(NEWS) \
	| pandoc -f rst -t gfm --wrap=none

