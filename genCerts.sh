#!/bin/bash

echo "----------------------------"
echo "|  Cert Generator |"
echo "----------------------------"
echo

CA_KEY="ca-key.pem"
CA_CERT="ca.pem"
CA_SUBJECT="docker-CA" #docker host name
CA_EXPIRE="10000"

CA_SIZE="4096"

SSL_CONFIG="openssl.cnf"
SSL_KEY="key.pem"
SSL_CSR="key.csr"
SSL_CERT="cert.pem"
SSL_SIZE="4096"
SSL_EXPIRE="10000"

SSL_SUBJECT="client"
SSL_DNS=$2
SSL_IP=$1

export DEBUG=${DEBUG:=1}

echo "--> Certificate Authority"

if [[ -e ./${CA_KEY} ]]; then
    echo "====> Using existing CA Key ${CA_KEY}"
else
    echo "====> Generating new CA key ${CA_KEY}"
    openssl genrsa -out ${CA_KEY} ${CA_SIZE}
fi

if [[ -e ./${CA_CERT} ]]; then
    echo "====> Using existing CA Certificate ${CA_CERT}"
else
    echo "====> Generating new CA Certificate ${CA_CERT}"
    openssl req -x509 -new -nodes -key ${CA_KEY} -days ${CA_EXPIRE} -out ${CA_CERT} -subj "/CN=${CA_SUBJECT}"  || exit 1


fi

[[ -n $DEBUG ]] && cat $CA_CERT

echo "====> Generating new config file ${SSL_CONFIG}"
cat > ${SSL_CONFIG} <<EOM
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
EOM

if [[ -n ${SSL_DNS} || -n ${SSL_IP} ]]; then
    cat >> ${SSL_CONFIG} <<EOM
subjectAltName = @alt_names
[alt_names]
EOM

    IFS=","
    dns=(${SSL_DNS})
    dns+=(${SSL_SUBJECT})
    for i in "${!dns[@]}"; do
      echo DNS.$((i+1)) = ${dns[$i]} >> ${SSL_CONFIG}
    done

    if [[ -n ${SSL_IP} ]]; then
        ip=(${SSL_IP})
        for i in "${!ip[@]}"; do
          echo IP.$((i+1)) = ${ip[$i]} >> ${SSL_CONFIG}
        done
    fi
fi

echo "====> Server Generating new SSL KEY ${SERVER_KEY}"
openssl genrsa -out ${SERVER_KEY} ${SSL_SIZE}  || exit 1

echo "====> Generating new SSL CSR ${SERVER_CSR}"
openssl req -new -key ${SERVER_KEY} -out ${SERVER_CSR} -subj "/CN=${SERVER_SUBJECT}" -config ${SSL_CONFIG}  || exit 1

echo "====> Generating new SSL CERT ${SERVER_CERT}"
openssl x509 -req -in ${SERVER_CSR} -CA ${CA_CERT} -CAkey ${CA_KEY} -CAcreateserial -out ${SERVER_CERT} \
    -days ${SSL_EXPIRE} -extensions v3_req -extfile ${SSL_CONFIG}  || exit 1


echo "====> Client Generating new SSL KEY ${CLIENT_KEY}"
openssl genrsa -out ${CLIENT_KEY} ${SSL_SIZE}  || exit 1

echo "====> Generating new SSL CSR ${CLIENT_CSR}"
openssl req -new -key ${CLIENT_KEY} -out ${CLIENT_CSR} -subj "/CN=${CLIENT_SUBJECT}" -config ${SSL_CONFIG}  || exit 1

echo "====> Generating new SSL CERT ${CLIENT_CERT}"
openssl x509 -req -in ${CLIENT_CSR} -CA ${CA_CERT} -CAkey ${CA_KEY} -CAcreateserial -out ${CLIENT_CERT} \
    -days ${SSL_EXPIRE} -extensions v3_req -extfile ${SSL_CONFIG}  || exit 1

echo -n
echo -n
echo "***** CA CERT"
cat $CA_CERT
echo -n
echo -n
echo "***** SERVER_KEY"
cat $SERVER_KEY
echo -n
echo -n


echo "***** CLIENT_KEY"
cat $CLIENT_KEY
echo -n
echo -n
echo "***** CLIENT CERT"
cat $CLIENT_CERT
echo -n
echo -n

