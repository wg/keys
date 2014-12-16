#ifndef SERVER_H
#define SERVER_H

typedef struct {
    pthread_t thread;
    int sockpair[2];
    interface ifa;
    X509 *cert;
    EVP_PKEY *pk;
} server_state;

server_state *server_start(interface, X509 *, EVP_PKEY *);
void server_stop(server_state *);
void server_join(server_state *);

void start(SSL *);
void  loop(SSL *, idx *, kdfp *, uint8_t *);
void reply(SSL *, uint32_t, uint32_t, uint32_t);

void pong(int, EVP_PKEY *, interface *, uint16_t);

int server_sock(SSL_CTX **, X509 *, EVP_PKEY *, interface *, sockaddr6 *);

#endif /* SERVER_H */
