// Copyright (C) 2013 - Will Glozer. All rights reserved.

#include <stdio.h>
#include <string.h>
#include <openssl/crypto.h>
#include <sodium/version.h>
#include "version.h"

const char *keys_version() {
    static char version[1024];
    const  char *keys   = "keys "   KEYS_VERSION;
    const  char *sodium = sodium_version_string();
    const  char *ssl    = SSLeay_version(SSLEAY_VERSION);

    int len = strchr(strchr(ssl, ' ') + 1, ' ') - ssl;
    snprintf(version, sizeof(version), "%s / %.*s / sodium %s", keys, len, ssl, sodium);

    return version;
}
