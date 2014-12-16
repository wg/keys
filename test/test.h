#ifndef TEST_H
#define TEST_H

#include <pthread.h>
#include <signal.h>
#include <openssl/err.h>
#include <openssl/ssl.h>
#include <openssl/engine.h>

#include "interface.h"
#include "pki.h"
#include "db.h"
#include "protocol.h"
#include "server.h"
#include "tinymt64.h"

char *temp_dir();
char *chdir_temp_dir();
void rmdir_temp_dir(char *);
void corrupt(char *, off_t);

void db_init(uint8_t *, kdfp *);
idx *db_load(uint8_t *, kdfp *);
void db_destroy(idx *);

uint8_t *encode_id(uint64_t);
idx *db_with_entry(char *, uint8_t *);

void entry_equals(entry *, entry *);

void init_server(kdfp *, uint8_t *, size_t, uint8_t *kek);
server_state *run_server(char *, uint8_t *);
void destroy_server(server_state *, kdfp *, uint8_t *);

void start_client(uint8_t *);
void stop_client();
SSL *client(uint8_t *);
void disconnect(SSL *s);

entry *parse(char *, uint32_t *);

uint64_t rand64(tinymt64_t *, uint64_t);
uint64_t time_us();

#endif /* TEST_H */
