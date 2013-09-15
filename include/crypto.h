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

#define  BOX_LEN(size)         ((32 * 2) + size)
#define  BOX_PTR(base, offset) ((box *) (((uint8_t *) base) + offset))

typedef struct kdfp {
    uint8_t salt[SALT_LEN];
    uint64_t N;
    uint32_t r;
    uint32_t p;
} kdfp;

typedef struct {
    uint8_t  iv[32];
    uint8_t tag[32];
    uint8_t data[];
} box;

bool derive_kek(uint8_t *, size_t, kdfp *, uint8_t *);
bool prompt_kek(char *, kdfp *, uint8_t *, bool);

bool decrypt_gcm(uint8_t *, uint8_t *, void *, size_t, uint8_t *);
void encrypt_gcm(uint8_t *, uint8_t *, void *, size_t, uint8_t *);

bool decrypt_box(uint8_t *, box *, size_t);
void encrypt_box(uint8_t *, box *, size_t);

void rand_bytes(uint8_t *, size_t);

#endif
