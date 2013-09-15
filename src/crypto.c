// Copyright (C) 2013 - Will Glozer. All rights reserved.

#include <assert.h>
#include <string.h>

#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/rand.h>

#include "config.h"
#include "crypto.h"
#include "crypto_scrypt.h"

bool derive_kek(uint8_t *passwd, size_t len, kdfp *kdfp, uint8_t *kek) {
    uint8_t *salt = kdfp->salt;
    uint64_t N    = kdfp->N;
    uint64_t r    = kdfp->r;
    uint64_t p    = kdfp->p;
    return crypto_scrypt(passwd, len, salt, SALT_LEN, N, r, p, kek, KEY_LEN) == 0;
}

bool prompt_kek(char *prompt, kdfp *kdfp, uint8_t *kek, bool verify) {
  char passwd[PASSWD_MAX];
  bool ok = false;

  if (!EVP_read_pw_string(passwd, PASSWD_MAX - 1, prompt, verify)) {
      ok = derive_kek((uint8_t *) passwd, strlen(passwd), kdfp, kek);
  }
  OPENSSL_cleanse(passwd, PASSWD_MAX);

  return ok;
}

bool decrypt_gcm(uint8_t *key, uint8_t *iv, void *addr, size_t len, uint8_t *tag) {
    EVP_CIPHER_CTX ctx;
    int rc, tmp;

    EVP_CIPHER_CTX_init(&ctx);
    assert(EVP_DecryptInit_ex(&ctx, EVP_aes_256_gcm(), NULL, NULL, NULL));
    EVP_CIPHER_CTX_ctrl(&ctx, EVP_CTRL_GCM_SET_IVLEN, IV_LEN, NULL);
    EVP_CIPHER_CTX_ctrl(&ctx, EVP_CTRL_GCM_SET_TAG,  TAG_LEN, tag);
    assert(EVP_DecryptInit_ex(&ctx, NULL, NULL, key, iv));
    assert(EVP_DecryptUpdate(&ctx, addr, &tmp, addr, len));
    rc = EVP_CipherFinal_ex(&ctx, NULL, &tmp);
    EVP_CIPHER_CTX_cleanup(&ctx);

    return rc == 1;
}

void encrypt_gcm(uint8_t *key, uint8_t *iv, void *addr, size_t len, uint8_t *tag) {
    EVP_CIPHER_CTX ctx;
    int tmp;

    EVP_CIPHER_CTX_init(&ctx);
    assert(EVP_EncryptInit_ex(&ctx, EVP_aes_256_gcm(), NULL, NULL, NULL));
    EVP_CIPHER_CTX_ctrl(&ctx, EVP_CTRL_GCM_SET_IVLEN, IV_LEN, NULL);
    assert(EVP_EncryptInit_ex(&ctx, NULL, NULL, key, iv));
    assert(EVP_EncryptUpdate(&ctx, addr, &tmp, addr, len));
    assert(EVP_EncryptFinal_ex(&ctx, NULL, &tmp));
    EVP_CIPHER_CTX_ctrl(&ctx, EVP_CTRL_GCM_GET_TAG, TAG_LEN, tag);
    EVP_CIPHER_CTX_cleanup(&ctx);
}

bool decrypt_box(uint8_t *key, box *box, size_t len) {
    return decrypt_gcm(key, box->iv, box->data, len, box->tag);
}

void encrypt_box(uint8_t *key, box *box, size_t len) {
    rand_bytes(box->iv, IV_LEN);
    encrypt_gcm(key, box->iv, box->data, len, box->tag);
}

void rand_bytes(uint8_t *buf, size_t len) {
    assert(RAND_bytes(buf, len) == 1);
}
