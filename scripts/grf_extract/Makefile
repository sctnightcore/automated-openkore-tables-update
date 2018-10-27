#!make
OBJECTS=main.o zlib.o hash_tables.o grf.o euc_kr.o
OBJECTS32=$(patsubst %.o,%_32.o,$(OBJECTS))
OBJECTS64=$(patsubst %.o,%_64.o,$(OBJECTS))
DIST_FILES=libgrf-^.zip libgrf-^.tar.gz
TARGET=libgrf.a
TARGET64=libgrf64.a
GE_TARGET_32=grf_extract_32
GE_TARGET_64=grf_extract_64
BUILD=unknown
LDFLAGS=-static
LDFLAGS_TEST=
INCLUDES=-Iincludes -Izlib
ifndef DEBUG
DEBUG=yes
endif
ifeq ($(DEBUG),no)
CFLAGS=-pipe -O3 -Wall --std=gnu99
CXXFLAGS=-pipe -O3 -Wall
else
CFLAGS=-pipe -g -ggdb -O0 -Wall --std=gnu99 -D__DEBUG
CXXFLAGS=-pipe -g -ggdb -O0 -Wall -D__DEBUG
endif

ZOBJS = adler32.o compress.o crc32.o gzio.o uncompr.o deflate.o trees.o \
        zutil.o inflate.o infback.o inftrees.o inffast.o

ZOBJS32=$(patsubst %.o,%_32.o,$(ZOBJS))
ZOBJS64=$(patsubst %.o,%_64.o,$(ZOBJS))

UNAME=$(shell uname -s  | sed -e 's/_.*$$//')
# *****
# *** Linux config
# *****
CC=gcc -m32
CC64=gcc
CXX=g++ -m32
CXX64=g++
STRIP=strip
BUILD=Linux
LINFLAGS=-fPIC -DPIC
GCC_VERSION=$(shell $(CC) -dumpversion | awk -F. '{ print $$1 }')
ifeq ($(GCC_VERSION),4)
CFLAGS+=-Wno-attributes
endif

GCC_VERSION=$(shell $(CC) -dumpversion)

linux/%_32.o: src/%.c
	$(CC) $(CFLAGS) $(LINFLAGS) $(INCLUDES) -c -o $@ $<

linux/%_64.o: src/%.c
	$(CC64) $(CFLAGS) $(LINFLAGS) $(INCLUDES) -c -o $@ $<

linux/%_64.o: zlib/%.c
	$(CC64) $(CFLAGS) $(LINFLAGS) $(INCLUDES) -c -o $@ $<

linux/%_32.o: zlib/%.c
	$(CC) $(CFLAGS) $(LINFLAGS) $(INCLUDES) -c -o $@ $<

.PHONY: make_dirs test dist gb

ifeq ($(BUILD),unknown)
all: ;@echo "Unknown system $(UNAME) !"
else
all: make_dirs $(GE_TARGET_64)
endif

make_dirs:
	@mkdir linux 2>/dev/null || true

$(GE_TARGET_32): linux/grf_extract_32.o $(patsubst %.o,linux/%.o,$(ZOBJS32) $(OBJECTS32))
	$(CC64) $(CFLAGS) $(LINFLAGS) -o $@ $^
ifeq ($(DEBUG),no)
	$(STRIP) $@
endif

$(GE_TARGET_64): linux/grf_extract_64.o $(patsubst %.o,linux/%.o,$(ZOBJS64) $(OBJECTS64))
	$(CC64) $(CFLAGS) $(LINFLAGS) -o $@ $^
ifeq ($(DEBUG),no)
	$(STRIP) $@
endif

version.sh: includes/grf.h
	cat $< | grep "define VERSION" | grep -E "MAJOR|MINOR|REVISION" | sed -e 's/^#define //;s/ /=/' >$@

libgrf-%.zip: $(TARGET) $(TARGET64) includes/libgrf.h $(wildcard examples/*) doc/README doc/grf_magic
	$(RM) $@
	zip -9r $@ $^ -x .svn '*.o' data

libgrf-%.tar.gz: $(TARGET) $(TARGET64) includes/libgrf.h $(wildcard examples/*) doc/README doc/grf_magic
	tar -cvzf $@ --exclude '*.o' --exclude '.svn' --exclude 'data' $^

dist: make_dirs version.sh
	. version.sh; for foo in $(subst ^,$$VERSION_MAJOR.$$VERSION_MINOR.$$VERSION_REVISION,$(DIST_FILES)); do $(MAKE) -C . "$$foo" DEBUG=no; done

grf_test_linux: linux/test_64.o $(TARGET64)
	$(CC64) $(CFLAGS) $(LINFLAGS) $(LDFLAGS_TEST) -o $@ $< -L. -lgrf64

ifeq ($(UNAME),Linux)
test: make_dirs grf_test_linux
	@LD_LIBRARY_PATH="." ./grf_test_linux

leak: make_dirs grf_test_linux
	@LD_LIBRARY_PATH="." valgrind --show-reachable=yes --leak-check=full ./grf_test_linux

gdb: make_dirs grf_test_linux
	@LD_LIBRARY_PATH="." gdb ./grf_test_linux

else
test: ;@echo "No test available for your platform ($(UNAME))."
endif

clean:
	$(RM) -r linux $(TARGET) $(TARGET64) $(GE_TARGET_64) grf_test_linux version.sh
	$(RM) $(subst ^,*.*.*,$(DIST_FILES))
