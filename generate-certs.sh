#!/bin/bash
# Generate certificates for your OpenSearch cluster

OPENSEARCH_DN="/C=IR/ST=MHD/L=Iran/O=MRM"   # Edit here and in opensearch.yml

mkdir -p certs/{ca,opensearch-dashboards}

# Root CA
openssl genrsa -out certs/ca/ca.key 2048
openssl req -new -x509 -sha256 -days 1095 -subj "$OPENSEARCH_DN/CN=CA" -key certs/ca/ca.key -out certs/ca/ca.pem

# Admin
openssl genrsa -out certs/ca/admin-temp.key 2048
openssl pkcs8 -inform PEM -outform PEM -in certs/ca/admin-temp.key -topk8 -nocrypt -v1 PBE-SHA1-3DES -out certs/ca/admin.key
openssl req -new -subj "$OPENSEARCH_DN/CN=ADMIN" -key certs/ca/admin.key -out certs/ca/admin.csr
openssl x509 -req -in certs/ca/admin.csr -CA certs/ca/ca.pem -CAkey certs/ca/ca.key -CAcreateserial -sha256 -out certs/ca/admin.pem
rm certs/ca/admin-temp.key certs/ca/admin.csr

# OpenSearch Dashboards
openssl genrsa -out certs/opensearch-dashboards/opensearch-dashboards-temp.key 2048
openssl pkcs8 -inform PEM -outform PEM -in certs/opensearch-dashboards/opensearch-dashboards-temp.key -topk8 -nocrypt -v1 PBE-SHA1-3DES -out certs/opensearch-dashboards/opensearch-dashboards.key
openssl req -new -subj "$OPENSEARCH_DN/CN=opensearch-dashboards" -key certs/opensearch-dashboards/opensearch-dashboards.key -out certs/opensearch-dashboards/opensearch-dashboards.csr
openssl x509 -req -in certs/opensearch-dashboards/opensearch-dashboards.csr -CA certs/ca/ca.pem -CAkey certs/ca/ca.key -CAcreateserial -sha256 -out certs/opensearch-dashboards/opensearch-dashboards.pem
rm certs/opensearch-dashboards/opensearch-dashboards-temp.key certs/opensearch-dashboards/opensearch-dashboards.csr

# Nodes
for NODE_NAME in "os-n1" "os-n2" "os-n3"
do
    mkdir "certs/${NODE_NAME}"
    openssl genrsa -out "certs/$NODE_NAME/$NODE_NAME-temp.key" 2048
    openssl pkcs8 -inform PEM -outform PEM -in "certs/$NODE_NAME/$NODE_NAME-temp.key" -topk8 -nocrypt -v1 PBE-SHA1-3DES -out "certs/$NODE_NAME/$NODE_NAME.key"
    openssl req -new -subj "$OPENSEARCH_DN/CN=$NODE_NAME" -key "certs/$NODE_NAME/$NODE_NAME.key" -out "certs/$NODE_NAME/$NODE_NAME.csr"
    openssl x509 -req -extfile <(printf "subjectAltName=DNS:localhost,IP:127.0.0.1,DNS:$NODE_NAME") -in "certs/$NODE_NAME/$NODE_NAME.csr" -CA certs/ca/ca.pem -CAkey certs/ca/ca.key -CAcreateserial -sha256 -out "certs/$NODE_NAME/$NODE_NAME.pem"
    rm "certs/$NODE_NAME/$NODE_NAME-temp.key" "certs/$NODE_NAME/$NODE_NAME.csr"
done
