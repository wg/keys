// Copyright (C) 2013 - Will Glozer. All rights reserved.

#include <assert.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "config.h"
#include "crypto.h"
#include "test.h"

uint8_t hex_value(char c) {
    if      (c <= '9') return c - '0';
    else if (c <= 'F') return c - 'A' + 10;
    else               return c - 'a' + 10;
}

void hex(uint8_t *b, char *s, size_t *len) {
    *len = strlen(s) / 2;
    for (char *c = s; *c; c++) {
        uint8_t high = hex_value(*c++ & 0x7f);
        uint8_t low  = hex_value(*c   & 0x7f);
        *b++ = (high << 4) | low;
    }
}

void encrypt_gcm256(char *ckey, char *civ, char *cdata, char *cctxt, char *ctag) {
    uint8_t key[32], iv[16], tag[TAG_LEN], otag[TAG_LEN];
    uint8_t data[1024], ctxt[1024];
    size_t iv_len, data_len, n;

    hex(key,  ckey,  &n);
    hex(iv,   civ,   &iv_len);
    hex(data, cdata, &data_len);
    hex(tag,  ctag,  &n);
    hex(ctxt, cctxt, &n);

    EVP_CIPHER_CTX ctx;
    int tmp;

    EVP_CIPHER_CTX_init(&ctx);
    assert(EVP_EncryptInit_ex(&ctx, EVP_aes_256_gcm(), NULL, NULL, NULL));
    EVP_CIPHER_CTX_ctrl(&ctx, EVP_CTRL_GCM_SET_IVLEN, iv_len, NULL);
    assert(EVP_EncryptInit_ex(&ctx, NULL, NULL, key, iv));
    assert(EVP_EncryptUpdate(&ctx, data, &tmp, data, data_len));
    assert(EVP_EncryptFinal_ex(&ctx, NULL, &tmp));
    EVP_CIPHER_CTX_ctrl(&ctx, EVP_CTRL_GCM_GET_TAG, TAG_LEN, otag);
    EVP_CIPHER_CTX_cleanup(&ctx);

    assert(!memcmp(tag, otag, TAG_LEN));
    assert(!memcmp(data, ctxt, n));
}

void test_sanity() {
    char *key, *iv, *tag, *data, *ctxt;

    // AES-256 GCM test vectors from "The Galois/Counter Mode of Operation (GCM)"
    // NIST proposal.

    key  = "00000000000000000000000000000000"
           "00000000000000000000000000000000";
    iv   = "000000000000000000000000";
    data = "";
    ctxt = "";
    tag  = "530f8afbc74536b9a963b4f1c4cb738b";
    encrypt_gcm256(key, iv, data, ctxt, tag);

    key  = "00000000000000000000000000000000"
           "00000000000000000000000000000000";
    iv   = "000000000000000000000000";
    data = "00000000000000000000000000000000";
    ctxt = "cea7403d4d606b6e074ec5d3baf39d18";
    tag  = "d0d1c8a799996bf0265b98b5d48ab919";
    encrypt_gcm256(key, iv, data, ctxt, tag);

    key  = "feffe9928665731c6d6a8f9467308308"
           "feffe9928665731c6d6a8f9467308308";
    iv   = "cafebabefacedbaddecaf888";
    data = "d9313225f88406e5a55909c5aff5269a"
           "86a7a9531534f7da2e4c303d8a318a72"
           "1c3c0c95956809532fcf0e2449a6b525"
           "b16aedf5aa0de657ba637b391aafd255";
    ctxt = "522dc1f099567d07f47f37a32a84427d"
           "643a8cdcbfe5c0c97598a2bd2555d1aa"
           "8cb08e48590dbb3da7b08b1056828838"
           "c5f61e6393ba7a0abcc9f662898015ad";
    tag  = "b094dac5d93471bdec1a502270e3cc6c";
    encrypt_gcm256(key, iv, data, ctxt, tag);


    uint8_t kek[KEY_LEN] = { 0 };
    kdfp kdfp = { .N = 2, .r = 1, .p = 1};
    uint32_t line;
    char *dir;
    idx *idx;
    entry *entry;

    // index (key) decryption failure

    dir = chdir_temp_dir();

    init_index("index", kek, &kdfp);
    corrupt("index", KDFP_LEN + TAG_LEN + IV_LEN);
    idx = open_index("index", &kdfp);
    assert(idx != NULL && load_index(&idx, kek) == false);
    close_index(idx);

    unlink("index");
    rmdir_temp_dir(dir);

    // index (data) decryption failure

    dir = chdir_temp_dir();

    init_index("index", kek, &kdfp);
    entry = parse("foo: bar", &line);
    idx = db_load(kek, &kdfp);
    assert(update_index("index", idx, kek, &kdfp, encode_id(1), entry));
    close_index(idx);
    corrupt("index", KDFP_LEN + ((TAG_LEN + IV_LEN) * 2) + KEY_LEN);

    idx = open_index("index", &kdfp);
    assert(idx != NULL && load_index(&idx, kek) == false);
    close_index(idx);

    unlink("index");
    rmdir_temp_dir(dir);

    // entry decryption failure

    uint8_t id0[ID_LEN];
    char path[PATH_MAX];
    dir = chdir_temp_dir();

    idx = db_with_entry("user: foo", id0);
    entry_path(path, id0, NULL);
    corrupt(path, TAG_LEN + IV_LEN);
    assert(load_entry(path, idx->key) == NULL);

    db_destroy(idx);
}
