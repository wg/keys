#ifndef CRYPTO_H
#define CRYPTO_H

#include <stdbool.h>
#include <stdint.h>
#include <sys/types.h>

#define    IV_LEN  16
#define   TAG_LEN  16
#define   KEY_LEN  32
#define  SALT_LEN  16

#define PASSWD_MAX 256

typedef struct kdfp {
    uint8_t salt[SALT_LEN];
    uint64_t N;
    uint32_t r;
    uint32_t p;
} kdfp;

bool derive_kek(uint8_t *, size_t, kdfp *, uint8_t *);
bool prompt_kek(char *, kdfp *, uint8_t *, bool);

bool decrypt_gcm(uint8_t *key, uint8_t *iv, void *addr, size_t len, uint8_t *tag);
void encrypt_gcm(uint8_t *key, uint8_t *iv, void *addr, size_t len, uint8_t *tag);

void rand_bytes(uint8_t *buf, size_t len);

#endif
