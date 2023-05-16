#!/bin/bash

# Not sure if this can work for others but kafka requires the generated keystore should contain hostname (domains)!!!
# Fixme - keytool -keystore server.keystore.jks -alias localhost -validity {validity} -genkey -keyalg RSA -destkeystoretype pkcs12 -ext SAN=DNS:{FQDN},IP:{IPADDRESS1}
# The following script refers to the following url:
#   - https://kafka.apache.org/documentation/#security_ssl
#   - https://raw.githubusercontent.com/confluentinc/confluent-platform-security-tools/master/kafka-generate-ssl.sh
# Instructs Bash to immediately exit the script or terminate the current shell session if any command within the script exits with a non-zero status. By default, Bash scripts continue executing even if individual commands fail
set -e

# Constants
KEYSTORE_WORKING_DIR="keystore"
TRUSTSTORE_WORKING_DIR="truststore"
CA_WORKING_DIR="cert-auth"

CA_CONFIG_FILENAME="openssl-ca.cnf"
KEYSTORE_FILENAME="kafka.keystore.jks"
TRUSTSTORE_FILENAME="kafka.truststore.jks"
VALIDITY_IN_DAYS=999999


CA_CERT_FILE="ca-cert.pem"
CA_KEY_FILE="ca-key.pem"
KEYSTORE_SIGN_REQUEST="cert-file.csr"
KEYSTORE_SIGNED_CERT="cert-signed.pem"

STDOUT_SECTION_START=">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
STDOUT_SECTION_END="<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"



# >>> Check if keytool is available >>>
echo
echo $STDOUT_SECTION_START
if ! command -v keytool &> /dev/null
then
    echo "keytool not found, installing JDK..."
    sudo apt-get update
    sudo apt-get install -y default-jdk
else
    echo "keytool is already installed."
fi
echo $STDOUT_SECTION_END
# <<< Check if keytool is available <<<


# >>> Sanitize the ssl files >>>
# Ensure all related files are not exist.
function file_exists_and_exit() {
  echo "'$1' cannot exist. Move or delete it before"
  echo "re-running this script."
  exit 1
}

if [ -e "$KEYSTORE_WORKING_DIR" ]; then
  file_exists_and_exit $KEYSTORE_WORKING_DIR
fi

if [ -e "$CA_CERT_FILE" ]; then
  file_exists_and_exit $CA_CERT_FILE
fi

if [ -e "$KEYSTORE_SIGN_REQUEST" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST
fi

if [ -e "$TRUSTSTORE_WORKING_DIR" ]; then
    file_exists_and_exit $TRUSTSTORE_WORKING_DIR
fi

if [ -e "$KEYSTORE_SIGNED_CERT" ]; then
  file_exists_and_exit $KEYSTORE_SIGNED_CERT
fi

if [ -e "$CA_WORKING_DIR" ]; then
  file_exists_and_exit $CA_WORKING_DIR
fi

if ! [ -e "$CA_CONFIG_FILENAME" ]; then
  echo "$CA_CONFIG_FILENAME does not exist. Due to a bug in OpenSSL, "
  echo "the x509 module will not copy requested extension fields from CSRs into the final certificate."
  echo "please create a \"$CA_CONFIG_FILENAME\" referring to the kafka doc."
fi
# <<< Sanitize the ssl files <<<


# >>> Generate a local certificate authority
echo
echo $STDOUT_SECTION_START
echo "Now the local certificate authority will be generated."
echo
echo "You will be prompted for the following:"
echo "  - A CA's private key password. Remember it."
echo "  - Personal information, such as your name."

mkdir $CA_WORKING_DIR
echo 01 > $CA_WORKING_DIR/serial.txt
touch $CA_WORKING_DIR/index.txt
openssl req -x509 -new -config openssl-ca.cnf -out $CA_WORKING_DIR/$CA_CERT_FILE -outform PEM -days $VALIDITY_IN_DAYS

echo
echo "Your local CA has been initialized"
echo $STDOUT_SECTION_END
# <<< Generate a local certificate authority <<<


# >>> Generate truststore. Import the ca-cert into the trustsore. >>>
echo
echo $STDOUT_SECTION_START
echo "Now the truststore will be generated from the certificate."
echo
echo "You will be prompted for:"
echo "  - the trust store's password (labeled 'keystore'). Remember this"
echo "  - a confirmation that you want to import the certificate"
mkdir $TRUSTSTORE_WORKING_DIR
keytool -keystore $TRUSTSTORE_WORKING_DIR/$TRUSTSTORE_FILENAME \
    -alias CARoot -import -file $CA_WORKING_DIR/$CA_CERT_FILE

echo
echo "Your local trustore has been initialized and the ca-cert.pem has been imported into your trustore."
echo $STDOUT_SECTION_END
# <<< Generate truststore. Import the ca-cert into the trustsore. <<<


# >>> Generate keystore >>>
echo
echo $STDOUT_SECTION_START
echo "Now, a keystore will be generated. Each broker and logical client needs its own"
echo "keystore. This script will create only one keystore. Run this script multiple"
echo "times for multiple keystores."
echo
echo "You will be prompted for the following:"
echo " - A keystore password. Remember it."
echo " - Personal information, such as your name."
echo " - A key password, for the key being generated within the keystore. Remember this."
mkdir $KEYSTORE_WORKING_DIR
keytool -keystore $KEYSTORE_WORKING_DIR/$KEYSTORE_FILENAME \
  -alias localhost -validity $VALIDITY_IN_DAYS -genkey -keyalg RSA -storetype pkcs12

echo
echo "Now the CA will be imported into the keystore."
echo
echo "You will be prompted for the keystore's password and a confirmation that you want to import the certificate."
keytool -keystore $KEYSTORE_WORKING_DIR/$KEYSTORE_FILENAME -alias CARoot \
  -import -file $CA_WORKING_DIR/$CA_CERT_FILE

echo
echo "Your local keystore has been initialized and the ca-cert.pem has been imported into your keystore."
echo $STDOUT_SECTION_END
# <<< Generate keystore <<<


# >>> Generate a CSR, and let the local CA signs it, and import it back to keystore >>>
echo
echo $STDOUT_SECTION_START
echo "Now a certificate signing request (CSR) will be made to the keystore."
echo
echo "You will be prompted for the keystore's password."
keytool -keystore $KEYSTORE_WORKING_DIR/$KEYSTORE_FILENAME -alias localhost \
  -certreq -file $KEYSTORE_WORKING_DIR/$KEYSTORE_SIGN_REQUEST

echo
echo "Now the CA's private key will sign the keystore's certificate."
echo
echo "You will be prompted for the CA's private key password."
openssl ca -config openssl-ca.cnf -policy signing_policy -extensions signing_req \
  -out $KEYSTORE_WORKING_DIR/$KEYSTORE_SIGNED_CERT -infiles $KEYSTORE_WORKING_DIR/$KEYSTORE_SIGN_REQUEST

echo
echo "Now the keystore's signed certificate will be imported back into the keystore."
echo
echo "You will be prompted for the keystore's password."
keytool -keystore $KEYSTORE_WORKING_DIR/$KEYSTORE_FILENAME -alias localhost -import \
  -file $KEYSTORE_WORKING_DIR/$KEYSTORE_SIGNED_CERT

echo
echo "Your CSR has been signed and imported back into your keystore"
echo $STDOUT_SECTION_END
# <<< Generate a CSR, and let the local CA signs it, and import it back to keystore <<<

echo
echo "All done!"
echo
echo "Delete intermediate files? They are:"
echo " - '$KEYSTORE_WORKING_DIR/$KEYSTORE_SIGN_REQUEST': the keystore's certificate signing request"
echo "   (that was fulfilled)"
echo " - '$KEYSTORE_WORKING_DIR/$KEYSTORE_SIGNED_CERT': the keystore's certificate, signed by the CA, and stored back"
echo "    into the keystore"
echo -n "Delete? [yn] "
read delete_intermediate_files

if [ "$delete_intermediate_files" == "y" ]; then
  rm $KEYSTORE_WORKING_DIR/$KEYSTORE_SIGN_REQUEST
  rm $KEYSTORE_WORKING_DIR/$KEYSTORE_SIGNED_CERT
fi