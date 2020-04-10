#!/bin/bash
ROOT_DIR='${ROOT_DIR}'
INTERMEDIATE_DIR='${INTERMEDIATE_DIR}'
PASSWORD='${PASSWORD}'
COUNTRY='${COUNTRY}'
STATE='${STATE}'
CITY='${CITY}'
ORG='${ORG}'
UNIT='${UNIT}'
DOMAIN='${DOMAIN}'

cd $ROOT_DIR
mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial

openssl genrsa -aes256 -out private/ca.key.pem -passout pass:$PASSWORD 4096
chmod 400 private/ca.key.pem

openssl req -config openssl.cnf \
    -key private/ca.key.pem \
    -new -x509 -days 7300 -sha256 -extensions v3_ca \
    -out certs/ca.cert.pem -passin pass:$PASSWORD \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$UNIT/CN=$DOMAIN"

chmod 444 certs/ca.cert.pem

cd $INTERMEDIATE_DIR
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber
echo "Root CA:  $PASSWORD" > $ROOT_DIR/private/password.txt
chown 0600 $ROOT_DIR/private/password.txt
