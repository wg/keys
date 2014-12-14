#ifndef INIT_H
#define INIT_H

bool init(char *, kdfp *, uint8_t *, size_t);
bool issue_client_cert(X509 *, EVP_PKEY *, X509 **, EVP_PKEY **);
void generate_password(uint8_t *, size_t);

#endif /* INIT_H */
