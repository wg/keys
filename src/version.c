// Copyright (C) 2013 - Will Glozer. All rights reserved.

#include <stdio.h>
#include <string.h>
#include <openssl/opensslv.h>
#include <sodium/version.h>
#include "version.h"

const char *keys_version() {
    static char version[1024];
    const  char *keys   = "keys "   KEYS_VERSION;
    const  char *sodium = "sodium " SODIUM_VERSION_STRING;
    const  char *ssl    = OPENSSL_VERSION_TEXT;

    int len = strchr(strchr(ssl, ' ') + 1, ' ') - ssl;
    snprintf(version, sizeof(version), "%s / %.*s / %s", keys, len, ssl, sodium);

    return version;
}
