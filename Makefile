CFLAGS := -std=c99 -Wall -Wextra -g
SSE2   := yes

TARGET ?= $(shell uname -s 2>/dev/null || echo unknown)
override TARGET := $(shell echo $(TARGET) | tr [A-Z] [a-z])

ifeq ($(TARGET), android)
	CC      := arm-linux-androideabi-gcc
	SYSROOT := $(ANDROID_NDK)/platforms/android-14/arch-arm/
	CFLAGS  += --sysroot=$(SYSROOT)
	LDFLAGS += -lc -Wl,--fix-cortex-a8 --sysroot=$(SYSROOT)
	SSE2    :=
	OPENSSL ?= /usr/local/openssl-1.0.1e-android-arm
else
	OPENSSL ?= /usr/local/openssl-1.0.1e
endif

ifeq ($(TARGET), linux)
	CFLAGS  += -D_POSIX_C_SOURCE=200809L -D_BSD_SOURCE
	LDFLAGS += -lpthread -ldl
endif

CFLAGS  += -DHAVE_CONFIG_H -I include -I $(OPENSSL)/include
LDFLAGS += -L $(OPENSSL)/lib -lssl -lcrypto -lm -lz

SRC      := $(filter-out $(if $(SSE2),%-nosse.c,%-sse.c),$(wildcard src/*.c))
OBJ       = $(patsubst src/%.c,$(OBJ_DIR)/%.o,$(SRC))
OBJ_DIR  := obj

ifeq ($(TARGET), android)
	OBJ := $(patsubst %/interface.o,%/netlink.o,$(OBJ))
endif

TEST_OBJ := $(patsubst test/%c,$(OBJ_DIR)/%o,$(wildcard test/*.c))

all: keys

clean:
	$(RM) $(OBJ) $(TEST_OBJ)

keys: $(OBJ)
	$(CC) -o $@ $^ $(LDFLAGS)

libkeys.so: $(filter-out %keys.o %client.o,$(OBJ)) $(OBJ_DIR)/native.o
	$(CC) -shared -o $@ $^ $(CFLAGS) $(LDFLAGS) -llog

test: tests
	./tests

tests: $(TEST_OBJ) $(filter-out %keys.o,$(OBJ))
	$(CC) -o $@ $^ $(LDFLAGS)

$(OBJ): | $(OBJ_DIR)

$(OBJ_DIR):
	@mkdir -p $@

$(OBJ_DIR)/%.o : src/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJ_DIR)/%.o : src/android/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJ_DIR)/%.o : test/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: all clean test
