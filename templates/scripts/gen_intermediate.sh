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
INTERMEDIATE_NAME="$1"
INTERMEDIATE_PASS="$2"

cd $ROOT_DIR
openssl genrsa -aes256 \
    -out $INTERMEDIATE_DIR/private/$INTERMEDIATE_NAME.key.pem \
    -passout pass:$INTERMEDIATE_PASS 4096
chmod 400 $INTERMEDIATE_DIR/private/$INTERMEDIATE_NAME.key.pem

openssl req -config $INTERMEDIATE_DIR/openssl.cnf \
    -key $INTERMEDIATE_DIR/private/$INTERMEDIATE_NAME.key.pem \
    -new -sha256 \
    -out $INTERMEDIATE_DIR/csr/$INTERMEDIATE_NAME.csr.pem -passin pass:$INTERMEDIATE_PASS \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORG/OU=$UNIT/CN=$INTERMEDIATE_NAME.$DOMAIN"

openssl ca -batch -config openssl.cnf -extensions v3_intermediate_ca \
    -days 3650 -notext -md sha256 \
    -in $INTERMEDIATE_DIR/csr/$INTERMEDIATE_NAME.csr.pem \
    -out $INTERMEDIATE_DIR/certs/$INTERMEDIATE_NAME.cert.pem \
    -passin pass:$PASSWORD

chmod 444 $INTERMEDIATE_DIR/certs/$INTERMEDIATE_NAME.cert.pem

cat $INTERMEDIATE_DIR/certs/$INTERMEDIATE_NAME.cert.pem \
    certs/ca.cert.pem > $INTERMEDIATE_DIR/certs/$INTERMEDIATE_NAME-ca-chain.cert.pem
chmod 444 $INTERMEDIATE_DIR/certs/$INTERMEDIATE_NAME-ca-chain.cert.pem

echo "$INTERMEDIATE_NAME:  $INTERMEDIATE_PASS" >> $INTERMEDIATE_DIR/private/password.txt
chown 0600 $INTERMEDIATE_DIR/private/password.txt
