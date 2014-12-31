// Copyright (C) 2014 - Will Glozer. All rights reserved.

#import <Foundation/Foundation.h>

#include "crypto.h"
#include "db.h"
#include "init.h"
#include "interface.h"
#include "pki.h"
#include "protocol.h"
#include "server.h"

bool keys_create(NSString *path, NSString *passwd, uint64_t N, uint32_t r, uint32_t p) {
    kdfp kdfp = { .N = N, .r = r, .p = p };
    const char *path8 = [path cStringUsingEncoding:NSUTF8StringEncoding];
    const char *passwd8 = [passwd cStringUsingEncoding:NSUTF8StringEncoding];
    return init((char *) path8, &kdfp, (uint8_t *) passwd8, strlen(passwd8));
}

server_state *keys_start(interface ifa) {
    X509 *cert;
    EVP_PKEY *pk;
    read_pem("server.pem", NULL, NULL, &pk, 1, &cert);
    return server_start(ifa, cert, pk);
}

void keys_close(void *arg, uint8_t *kek) {
    OPENSSL_cleanse(kek, KEY_LEN);
    close_index((idx *) arg);
}

void *keys_open(NSString *passwd, uint8_t *kek) {
    kdfp kdfp;
    idx *idx;

    if ((idx = open_index("index", &kdfp))) {
        const char *passwd8 = [passwd cStringUsingEncoding:NSUTF8StringEncoding];
        if (derive_kek((uint8_t *) passwd8, strlen(passwd8), &kdfp, kek, KEY_LEN)) {
            if (!load_index(&idx, kek)) {
                keys_close(idx, kek);
                idx = NULL;
            }
        }
    }

    return idx;
}

NSArray *keys_search(void *arg, NSString *term) {
    const char *term8 = [term cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableArray *array = [NSMutableArray array];
    uint32_t count = 128;
    uint8_t *matches[count];
    char path[PATH_MAX];

    search_index((idx *) arg, (uint8_t *) term8, strlen(term8), matches, &count);

    for (uint32_t i = 0; i < count; i++) {
        entry_path(path, matches[i], NULL);
        entry *entry = load_entry(path, ((idx *) arg)->key);

        if (entry) {
            NSMutableArray *attrs = [NSMutableArray arrayWithCapacity:entry->count * 2];
            for (uint32_t j = 0; j < entry->count; j++) {
                string *key = &entry->attrs[j].key;
                string *val = &entry->attrs[j].val;
                [attrs addObject:[[NSString alloc] initWithBytes:key->str length:key->len encoding:NSUTF8StringEncoding]];
                [attrs addObject:[[NSString alloc] initWithBytes:val->str length:val->len encoding:NSUTF8StringEncoding]];
            }
            [array addObject:attrs];
            close_entry(entry);
        }
    }

    return array;
}

NSData *keys_issue() {
    NSData *data = nil;
    EVP_PKEY *ik, *pk;
    X509 *issuer, *cert;
    char *ptr;
    long len;

    read_pem("server.pem", NULL, NULL, &ik, 1, &issuer);

    if (issue_client_cert(issuer, ik, &cert, &pk)) {
        BIO *out = BIO_new(BIO_s_mem());

        PEM_write_bio_PKCS8PrivateKey(out, pk, NULL, NULL, 0, NULL, NULL);
        PEM_write_bio_X509(out, issuer);
        PEM_write_bio_X509(out, cert);

        len = BIO_get_mem_data(out, &ptr);
        data = [NSData dataWithBytes:ptr length:len];

        BIO_free(out);
    }

    return data;
}
