**2020-03-03**: With two lines of code, you can become a CA and then sign your certificate as a CA. Then import the CA certificate (not the SSL certificate) into Chrome/Chromium. (This works for Linux.)

The entire process takes only 6 shell commands:
```sh
######################
# Become a Certificate Authority
######################

# Generate private key
openssl genrsa -des3 -out myCA.key 2048
# Generate root certificate
openssl req -x509 -new -nodes -key myCA.key -sha256 -days 1825 -out myCA.pem

######################
# Create CA-signed certs
######################

NAME=mydomain.com
# Generate private key
[[ -e $NAME.key ]] || openssl genrsa -out $NAME.key 2048
# Create certificate-signing request
[[ -e $NAME.csr ]] || openssl req -new -key $NAME.key -out $NAME.csr
# Create a config file for the extensions
>$NAME.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = foo.$NAME
DNS.2 = bar.$NAME
EOF
# Create the signed certificate
openssl x509 -req -in $NAME.csr -CA myCA.pem -CAkey myCA.key -CAcreateserial \
-out $NAME.crt -days 1825 -sha256 -extfile $NAME.ext
```

To recap:

1. Become a CA
2. Sign your certificate using your CA key
3. Import myCA.pem as an Authority in your Chrome settings
4. Use the .crt file in your serfer

