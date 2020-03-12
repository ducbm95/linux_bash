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

### Mechanism
Your server creates a key pair, consisting of a private and a public key. The server never gives out the private key, of course, but everyone may obtain a copy of the public key. The public key is embedded within a certificate container format (X.509). This container consists of meta information related to the wrapped key, e.g. the IP address or domain name of a server, the owner of that server, an e-mail contact address, when the key was created, how long it is valid, for which purposes it may be used for, and many other possible values.

The whole container is signed by a trusted certificate authority (= CA). The CA also has a private/public key pair. You give them your certificate, they verify that the information in the container are correct (e.g. is the contact information correct, does that certificate really belong to that server) and finally sign it with their private key. The public key of the CA needs to be installed on the user system. Most well known CA certificates are included already in the default installation of your favorite OS or browser.

When now a user connects to your server, your server uses the private key to sign some random data, packs that signed data together with its certificate (= public key + meta information) and sends everything to the client. What can the client do with that information?

First of all, it can use the public key within the certificate it just got sent to verify the signed data. Since only the owner of the private key is able to sign the data correctly in such a way that the public key can correctly verify the signature, it will know that whoever signed this piece of data, this person is also owning the private key to the received public key.

But what stops a hacker from intercepting the packet, replacing the signed data with data he signed himself using a different certificate and also replace the certificate with his own one? The answer is simply nothing.

That's why after the signed data has been verified (or before it is verified) the client verifies that the received certificate has a valid CA signature. Using the already installed public CA key, it verifies that the received public key has been signed by a known and hopefully trusted CA. A certificate that is not signed is not trusted by default. The user has to explicitly trust that certificate in his browser.

Finally it checks the information within the certificate itself. Does the IP address or domain name really match the IP address or domain name of the server the client is currently talking to? If not, something is fishy!

People may wonder: What stops a hacker from just creating his own key pair and just putting your domain name or IP address into his certificate and then have it signed by a CA? Easy answer: If he does that, no CA will sign his certificate. To get a CA signature, you must prove that you are really the owner of this IP address or domain name. The hacker is not the owner, thus he cannot prove that and thus he won't get a signature.

But what if the hacker registers his own domain, creates a certificate for that, and have that signed by a CA? This works, he will get it CA signed, it's his domain after all. However, he cannot use it for hacking your connection. If he uses this certificate, the browser will immediately see that the signed public key is for domain example.net, but it is currently talking to example.com, not the same domain, thus something is wrong again.

