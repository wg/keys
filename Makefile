CFLAGS := -std=c99 -Wall -Wextra
LIBS   := -lsodium -lssl -lcrypto -lm -lz
SSE2   := yes

XCODE  := /Applications/Xcode.app/Contents/Developer

ifdef TARGET
	ARCH   := $(word 1,$(subst -, ,$(TARGET)))
	SYSTEM := $(word 2,$(subst -, ,$(TARGET)))
else
	ARCH   := $(shell uname -m 2>/dev/null | sed s/amd64/x86_64/ || echo unknown)
	SYSTEM := $(shell uname -s 2>/dev/null | tr '[A-Z]' '[a-z]'  || echo unknown)
	TARGET := $(ARCH)-$(SYSTEM)
endif

ifeq ($(SYSTEM), android)
	CC      := arm-linux-androideabi-gcc
	SYSROOT := $(ANDROID_NDK)/platforms/android-14/arch-arm/
	CFLAGS  += --sysroot=$(SYSROOT)
	LDFLAGS += -Wl,--fix-cortex-a8 --sysroot=$(SYSROOT)
	LIBS    += -lc
	SSE2    :=
else ifeq ($(SYSTEM), iphoneos)
	SYSROOT := $(XCODE)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
	CFLAGS  += --sysroot=$(SYSROOT) -arch $(ARCH) -miphoneos-version-min=8.1
	SSE2    :=
else ifeq ($(SYSTEM), iphonesimulator)
	SYSROOT := $(XCODE)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk
	CFLAGS  += --sysroot=$(SYSROOT) -arch $(ARCH) -miphoneos-version-min=8.1
	SSE2    :=
else ifeq ($(SYSTEM), linux)
	CFLAGS  += -D_POSIX_C_SOURCE=200809L -D_BSD_SOURCE
	LIBS    += -lpthread -ldl
else ifeq ($(SYSTEM), freebsd)
	CFLAGS  += -D_WITH_DPRINTF
	LIBS    += -lpthread
endif

DEPS     := deps/$(TARGET)
OBJ_DIR  := obj/$(TARGET)

HEADERS  := sodium.h openssl/opensslv.h
CFLAGS   += -DHAVE_CONFIG_H -I$(OBJ_DIR) -Iinclude -I$(DEPS)/include
LDFLAGS  += -L$(DEPS)/lib

SRC      := $(filter-out $(if $(SSE2),%-nosse.c,%-sse.c),$(wildcard src/*.c))
OBJ       = $(patsubst src/%.c,$(OBJ_DIR)/%.o,$(SRC))
LIBKEYS  := $(OBJ_DIR)/libkeys.a

ifeq ($(TARGET), android)
	OBJ := $(patsubst %/interface.o,%/netlink.o,$(OBJ))
endif

TEST_OBJ := $(patsubst test/%c,$(OBJ_DIR)/%o,$(wildcard test/*.c))
LIBTEST  := $(OBJ_DIR)/libkeystest.a

keys: keys.o $(LIBKEYS)
	$(info LINK $@)
	@$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

$(LIBKEYS): $(filter-out %keys.o,$(OBJ))
	$(info AR $@)
	@$(AR) rcs $@ $^

libkeys.so: native.o $(LIBKEYS)
	$(info LINK $@)
	@$(CC) -shared $(LDFLAGS) -o $@ $^ $(CFLAGS) $(LIBS) -llog

test: tests
	./tests

$(LIBTEST): $(filter-out %test.o,$(TEST_OBJ))
	$(info AR $@)
	@$(AR) rcs $@ $^

tests: test.o $(LIBTEST) $(LIBKEYS)
	$(info LINK $@)
	@$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

clean:
	@$(RM) $(OBJ) $(TEST_OBJ) $(LIBKEYS) $(LIBTEST)
	@$(RM) -r $(OBJ_DIR)/include
	@$(RM) -r $(OBJ_DIR)/lib

$(OBJ):      $(HEADERS) | $(OBJ_DIR)
$(TEST_OBJ): $(HEADERS) | $(OBJ_DIR)

$(OBJ_DIR):
	@mkdir -p $@

$(OBJ_DIR)/%.o : %.c
	$(info CC $<)
	@$(CC) $(CFLAGS) -c -o $@ $<

$(OBJ_DIR)/version.o: $(OBJ_DIR)/version.h

$(OBJ_DIR)/version.h: .git/index
	@sed s,1.0.0,`git describe`, include/version.h > $@

$(HEADERS):
	$(info Buiding depenencies...)
	@$(MAKE) -C deps TARGETS=$(TARGET)

.PHONY: clean test

.SUFFIXES:
.SUFFIXES: .c .o .a .so .h

vpath %.c src
vpath %.c src/android
vpath %.c test
vpath %.h $(DEPS)/include
vpath %.o $(OBJ_DIR)
