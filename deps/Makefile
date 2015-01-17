TARGETS ?= x86_64-darwin x86_64-iphonesimulator arm64-iphoneos

SODIUM  := $(CURDIR)/libsodium-1.0.1
OPENSSL := $(CURDIR)/openssl-1.0.1l

XCODE_TOP = /Applications/Xcode.app/Contents/Developer/Platforms/$(1).platform/Developer
XCODE_SDK = $(call XCODE_TOP,$(1))/SDKs/$(1).sdk

XCODE_CFLAGS        = -miphoneos-version-min=8.1 -arch $(ARCH)
SODIUM_XCODE_CFLAGS = -isysroot $(call XCODE_SDK,$(1)) $(XCODE_CFLAGS)
OPENSSL_XCODE_FLAGS = CROSS_TOP=$(call XCODE_TOP,$(1)) CROSS_SDK=$(1).sdk

SODIUM_LIBS := $(foreach target,$(TARGETS),$(CURDIR)/$(target)/lib/libsodium.a)
CRYPTO_LIBS := $(foreach target,$(TARGETS),$(CURDIR)/$(target)/lib/libcrypto.a)
   SSL_LIBS := $(foreach target,$(TARGETS),$(CURDIR)/$(target)/lib/libssl.a)

FILTER = $(foreach v,$(2),$(if $(findstring $(1),$(v)),$(v)))

### build universal libs for iOS

ifneq ($(strip $(call FILTER,iphone,$(SODIUM_LIBS) $(CRYPTO_LIBS) $(SSL_LIBS))),)

SODIUM_LIB := $(CURDIR)/universal/libsodium.a
CRYPTO_LIB := $(CURDIR)/universal/libcrypto.a
   SSL_LIB := $(CURDIR)/universal/libssl.a

all: $(SODIUM_LIB) $(CRYPTO_LIB) $(SSL_LIB)

$(SODIUM_LIB): $(call FILTER,iphone,$(SODIUM_LIBS))
	@mkdir -p $(dir $@)
	lipo -create -output $@ $^

$(CRYPTO_LIB): $(call FILTER,iphone,$(CRYPTO_LIBS))
	@mkdir -p $(dir $@)
	lipo -create -output $@ $^

$(SSL_LIB): $(call FILTER,iphone,$(SSL_LIBS))
	@mkdir -p $(dir $@)
	lipo -create -output $@ $^

else

all: $(SODIUM_LIBS) $(CRYPTO_LIBS) $(SSL_LIBS)

endif

### build libsodium

$(SODIUM_LIBS): $(SODIUM).tar.gz
	$(eval TARGET := $(word 1,$(subst /, ,$(subst $(CURDIR), ,$@))))
	$(eval ARCH   := $(word 1,$(subst -, ,$(TARGET))))
	$(eval SYSTEM := $(word 2,$(subst -, ,$(TARGET))))

	$(info Building libsodium for $(TARGET)...)
	@rm -rf $(SODIUM)
	@tar xzf $(SODIUM).tar.gz

	$(if $(findstring iphonesimulator, $(SYSTEM)),$(eval CFLAGS := $(call SODIUM_XCODE_CFLAGS,iPhoneSimulator)))
	$(if $(findstring iphoneos,        $(SYSTEM)),$(eval CFLAGS := $(call SODIUM_XCODE_CFLAGS,iPhoneOS)))
	$(if $(findstring iphoneos,        $(SYSTEM)),$(eval HOST   := --host=x86_64-apple-darwin))

	$(eval FLAGS  := --disable-shared --enable-static $(HOST) CFLAGS="$(CFLAGS)")
	@cd $(SODIUM); ./configure --prefix=$(CURDIR)/$(TARGET) $(FLAGS)
	@$(MAKE) -C $(SODIUM) install

### build libcrypto and libssl

$(CRYPTO_LIBS): $(OPENSSL).tar.gz
	$(eval TARGET := $(word 1,$(subst /, ,$(subst $(CURDIR), ,$@))))
	$(eval ARCH   := $(word 1,$(subst -, ,$(TARGET))))
	$(eval SYSTEM := $(word 2,$(subst -, ,$(TARGET))))

	$(info Building openssl for $(TARGET)...)
	@rm -rf $(OPENSSL)
	@tar xzf $(OPENSSL).tar.gz

	$(eval FLAGS :=)
	$(eval BUILD := ./config)
	$(if $(findstring iphonesimulator, $(SYSTEM)),$(eval FLAGS := $(call OPENSSL_XCODE_FLAGS,iPhoneSimulator)))
	$(if $(findstring iphoneos,        $(SYSTEM)),$(eval FLAGS := $(call OPENSSL_XCODE_FLAGS,iPhoneOS)))
	$(if $(findstring iphone,          $(SYSTEM)),$(eval BUILD  = ./Configure iphoneos-cross no-asm))
	$(if $(findstring x86_64-darwin,   $(TARGET)),$(eval BUILD  = ./Configure darwin64-x86_64-cc))
	$(if $(findstring iphone,          $(SYSTEM)),$(eval CCC   := CC="gcc $(XCODE_CFLAGS)"))
	$(if $(findstring freebsd,         $(SYSTEM)),$(eval CCC   := CC="cc"))

	$(eval BUILD += no-shared no-ssl2 no-ssl3 no-dtls no-dso no-psk no-srp)

	cd $(OPENSSL); $(CCC) $(BUILD) --prefix=$(CURDIR)/$(TARGET)
	@$(MAKE) -C $(OPENSSL) $(FLAGS) install

clean:
	rm -rf $(TARGETS)
	rm -rf $(SODIUM)
	rm -rf $(OPENSSL)

.PHONY: all clean
.SUFFIXES:
.SUFFIXES: .a
