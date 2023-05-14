# Enable SSL in Kafka

## 1. Generate Keystore in Brokers

Generate a new key pair and store it in a Java keystore.

```bash
keytool -keystore server.keystore.jks -alias hermes-kafka -validity 999999 -genkey -keyalg RSA -storetype pkcs12
```

- `keystore`: This option is used to specify the name and location of the keystore. The keystore is a database of keys. Private keys in a keystore have a certificate chain associated with them, which authenticates the corresponding public key.
- `alias`: This option is used to assign an alias (name) to the key pair. This alias is used to identify the specific key pair in the keystore.
- `validity`: This option is used to specify the number of days for which the key pair (and associated certificate) should be considered valid.
- `genkey`: This option is used to generate a key pair (a public key and associated private key). Wraps the public key into an X.509 v3 self-signed certificate, which is stored as a single-element certificate chain. This certificate chain and the private key are stored in a new keystore entry identified by alias.
- `keyalg`: This option is used to specify the algorithm to be used to generate the key pair. In this command, `RSA` is the specified algorithm.
- `storetype`: This option is used to specify the type of the keystore. In this command, `pkcs12` is the type of keystore. PKCS12 is a type of keystore that is widely supported and recommended for compatibility.

```bash
# Check if the keystore is sucessfully created
keytool -list -v -keystore server.keystore.jks
```

## 2. Set Up Local Certificate Authority

```bash
vim openssl-ca.cnf
```

Save the following listing into a file called openssl-ca.cnf and adjust the values for validity and common attributes as necessary.

```properties

HOME            = .
RANDFILE        = $ENV::HOME/.rnd
BASE_DIR        = cert-auth    # Note that this is a global var to store ca info.
CA_CERT_FILE    = ca-cert.pem
CA_KEY_FILE     = ca-key.pem


####################################################################
[ ca ]
default_ca    = CA_default      # The default ca section

# The following info is required for CA when it signs CSRs
[ CA_default ]
certificate   = $BASE_DIR/$CA_CERT_FILE   # The CA certifcate
private_key   = $BASE_DIR/$CA_KEY_FILE    # The CA private key
new_certs_dir = $BASE_DIR              # Location for new certs after signing
database      = $BASE_DIR/index.txt    # Database index file
serial        = $BASE_DIR/serial.txt   # The current serial number

default_days     = 999999        # How long to certify for
default_crl_days = 30           # How long before next CRL
default_md       = sha256       # Use public key default message digest(MD)
preserve         = no           # Keep passed DN ordering

x509_extensions = ca_extensions # The extensions to add to the cert

email_in_dn     = no            # Don't concat the email in the DN
copy_extensions = copy          # Required to copy SANs from CSR to cert

####################################################################
[ req ]
# The following info is required when CA is initialized and generating related key
default_bits       = 4096
default_keyfile    = $BASE_DIR/$CA_KEY_FILE
distinguished_name = ca_distinguished_name
x509_extensions    = ca_extensions
string_mask        = utf8only

####################################################################
[ ca_distinguished_name ]
countryName         = Country Name (2 letter code)
countryName_default = AU

stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = VIC

localityName                = Locality Name (eg, city)
localityName_default        = Melbourne

organizationName            = Organization Name (eg, company)
organizationName_default    = BugMakers404

organizationalUnitName         = Organizational Unit (eg, division)
organizationalUnitName_default = hermes

commonName         = Common Name (e.g. server FQDN or YOUR name)
commonName_default = Andrew Sun

emailAddress         = Email Address
emailAddress_default = tyriongump@gmail.com

####################################################################
[ ca_extensions ]

subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always, issuer
basicConstraints       = critical, CA:true
keyUsage               = keyCertSign, cRLSign

####################################################################
[ signing_policy ]
countryName            = optional
stateOrProvinceName    = optional
localityName           = optional
organizationName       = optional
organizationalUnitName = optional
commonName             = supplied
emailAddress           = optional

####################################################################
[ signing_req ]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
basicConstraints       = CA:FALSE
keyUsage               = digitalSignature, keyEncipherment
```

Then create a database and serial number file, these will be used to keep track of which certificates were signed with this CA. Both of these are simply text files that reside in the same directory as your CA keys.

```bash
echo 01 > serial.txt
touch index.txt
```

Generate a Certificate Authority (CA) certificate

```bash
openssl req -x509 -config openssl-ca.cnf -newkey rsa:4096 -sha256 -nodes -out cacert.pem -outform PEM
```

## 3. Certificate Signing Request(CSR)

Generate a Certificate Signing Request (CSR) from the key pair in the keystore

```bash
keytool -keystore server.keystore.jks -certreq -alias hermes-kafka -file server.csr
```

## 4. Sign the CSR

Sign the CSR with the CA certificate to generate a server certificate

```bash
openssl ca -config openssl-ca.cnf -policy signing_policy -extensions signing_req -out server_certificate.pem -infiles server.csr
```

To view the content inside the file cert-signed, run the below command.

```bash
keytool -printcert -v -file server_certificate.pem
```

## 5. Adding the Signed Cert in to your KeyStore

Import the CA certificate into the keystore so that the CA is trusted

```bash
keytool -keystore server.keystore.jks -import -alias CARoot -file cacert.pem
```


```bash
keytool -keystore server.keystore.jks -import -alias hermes-kafka -file server_certificate.pem
```

Import CA to clients' truststone

```bash
keytool -keystore server.truststore.jks -alias CARoot -import -file cacert.pem
```

Signing the certificate
