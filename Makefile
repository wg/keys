CFLAGS := -std=c99 -Wall -Wextra
LIBS   := -lssl -lcrypto -lm -lz
SSE2   := yes

TARGET ?= $(shell uname -s 2>/dev/null || echo unknown)
override TARGET := $(shell echo $(TARGET) | tr [A-Z] [a-z])

ifeq ($(TARGET), android)
	CC      := arm-linux-androideabi-gcc
	SYSROOT := $(ANDROID_NDK)/platforms/android-14/arch-arm/
	CFLAGS  += --sysroot=$(SYSROOT)
	LDFLAGS += -Wl,--fix-cortex-a8 --sysroot=$(SYSROOT)
	LIBS    += -lc
	SSE2    :=
	NACL    ?= deps/android
	OPENSSL ?= /usr/local/openssl-1.0.1g-android-arm
else
	NACL    ?= deps/nacl/build/$(shell hostname -s)
	OPENSSL ?= /usr/local/openssl-1.0.1g
endif

ifeq ($(TARGET), linux)
	CFLAGS  += -D_POSIX_C_SOURCE=200809L -D_BSD_SOURCE
	LIBS    += -lpthread -ldl
else ifeq ($(TARGET), freebsd)
	LIBS    += -lpthread
endif

CFLAGS  += -DHAVE_CONFIG_H -I include -I $(OPENSSL)/include
LDFLAGS += -L $(OPENSSL)/lib

OBJ_DIR  := obj

SRC      := $(filter-out $(if $(SSE2),%-nosse.c,%-sse.c),$(wildcard src/*.c))
OBJ      := $(patsubst src/%.c,$(OBJ_DIR)/%.o,$(SRC)) $(OBJ_DIR)/randombytes.o
LIBKEYS  := $(OBJ_DIR)/libkeys.a

ifeq ($(TARGET), android)
	OBJ := $(patsubst %/interface.o,%/netlink.o,$(OBJ))
endif

TEST_OBJ := $(patsubst test/%c,$(OBJ_DIR)/%o,$(wildcard test/*.c))
LIBTEST  := $(OBJ_DIR)/libkeystest.a

keys: keys.o $(LIBKEYS)
	@echo LINK $@
	@$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

$(LIBKEYS): $(filter-out %keys.o,$(OBJ))
	@echo AR $@
	@$(AR) rcs $@ $^

libkeys.so: native.o $(LIBKEYS)
	@echo LINK $@
	@$(CC) -shared $(LDFLAGS) -o $@ $^ $(CFLAGS) $(LIBS) -llog

test: tests
	./tests

$(LIBTEST): $(filter-out %test.o,$(TEST_OBJ))
	@echo AR $@
	@$(AR) rcs $@ $^

tests: test.o $(LIBTEST) $(LIBKEYS)
	@echo LINK $@
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

clean:
	@$(RM) $(OBJ) $(TEST_OBJ) $(LIBKEYS) $(LIBTEST)
	@$(RM) -r $(OBJ_DIR)/include
	@$(RM) -r $(OBJ_DIR)/lib

$(OBJ):      | nacl $(OBJ_DIR)
$(TEST_OBJ): | nacl $(OBJ_DIR)
$(OBJ_DIR)/native.o: | nacl

$(OBJ_DIR):
	@mkdir -p $@

$(OBJ_DIR)/%.o : %.c
	@echo CC $<
	@$(CC) $(CFLAGS) -c -o $@ $<

# NaCl build

nacl: $(OBJ_DIR)/lib/libnacl.a | $(OBJ_DIR)
	$(eval  CFLAGS += -I $(OBJ_DIR)/include)
	$(eval LDFLAGS += -L $(OBJ_DIR)/lib)
	$(eval    LIBS += -lnacl)

$(NACL)/bin/okabi:
	@echo Building NaCl
	@cd deps/nacl && ./do

$(OBJ_DIR)/include/crypto_box.h: $(NACL)/bin/okabi
	@mkdir -p $(OBJ_DIR)/include
	@$(eval NACL_ARCH := $(shell $(NACL)/bin/okabi | head -1))
	@echo CP $(NACL)/include/$(NACL_ARCH)
	@cp -r $(NACL)/include/$(NACL_ARCH)/*.h $(OBJ_DIR)/include

$(OBJ_DIR)/lib/libnacl.a: $(OBJ_DIR)/include/crypto_box.h
	@mkdir -p $(OBJ_DIR)/lib
	@$(eval NACL_ARCH := $(shell $(NACL)/bin/okabi | head -1))
	@echo CP $(NACL)/lib/$(NACL_ARCH)/libnacl.a
	@cp $(NACL)/lib/$(NACL_ARCH)/libnacl.a $@

$(OBJ_DIR)/randombytes.o: $(OBJ_DIR)/lib/libnacl.a
	@$(eval NACL_ARCH := $(shell $(NACL)/bin/okabi | head -1))
	@echo CP $(NACL)/lib/$(NACL_ARCH)/randombytes.o
	@cp $(NACL)/lib/$(NACL_ARCH)/randombytes.o $@

.PHONY: clean test nacl

.SUFFIXES:
.SUFFIXES: .c .o .a .so

vpath %.c src
vpath %.c src/android
vpath %.c test
vpath %.o $(OBJ_DIR)
