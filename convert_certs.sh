#!/bin/bash -e
# X509 certificates;
# Convert (regular) ASN.1 PEM certificate chain to pkcs7 DER. Also convert back and verify that they match.
# Comment: This is not a very useful tool, rather it serves as a reference for these certificate formats and openssl conversion commands :)


### QUICK SUMMARY OF FORMATS ###

# CERTIFICATE FORMAT
# x509 = very common type of public certificate (e.g. used in TLS)

# DATA STRUCTURE
# ASN.1 = format of cert(s) can be encoded in e.g. PEM or DER format
# pkcs7 = multi-purpose format for "storing signed and/or encrypted data", e.g. cert(s) and CRLs

# DATA ENCODING
# PEM = base64 encoding of data
# BER = a superset of DER see below
# DER = binary encoding of data ("is a restricted variant of BER [...] DER encodings are valid BER encodings")
#            src: https://en.wikipedia.org/wiki/X.690#DER_encoding

################################



# --- PREREQUISITE --- #
#FIRST: get a regular pem cert chain, this can be downloaded from firefox if you look at a site's cert for example.
#        fullchain.asn1.pem


# --- CONVERT CHAIN --- #
echo "Converting from ASN.1 PEM  (usually called .pem)"
echo "Converting to pkcs7 PEM (usually called .p7b)..."
openssl crl2pkcs7 -nocrl -certfile fullchain.asn1.pem -out results/fullchain.p7b.pem

echo "Converting to pkcs7 DER (usually called .p7b)..."
openssl pkcs7 -in results/fullchain.p7b.pem -out results/fullchain.p7b.der -outform der

#We can also convert to ASN.1 DER like this:
#openssl x509 -outform der -in fullchain.asn1.pem -out results.fullchain.asn1.der

# --- CONVERT BACK CHAIN (for verification purposes) --- #
echo "Converting back to ASN.1 PEM (usually called .pem)..."
openssl pkcs7 -inform der -in results/fullchain.p7b.der -out results/fullchain.asn1.pem -print_certs


# --- CHECK RESULTS --- #
echo

#Checks whether OpenSSL can parse our _first_ cert and if the new converted cert matches the original
INIT="$(openssl x509 -in fullchain.asn1.pem -text | sha1sum | head --bytes=40)"
FINAL="$(openssl x509 -in results/fullchain.asn1.pem -text | sha1sum | head --bytes=40)"
if [[ "${INIT}" == "${FINAL}" ]]; then
    echo "Conversion seems OK (comparing plaintext hash of _first_ cert)"
    echo
else
    echo "Conversion ERROR"
    exit 1
fi

echo "Performing full certificate chain validation..."
if [ -f 'ca.asn1.pem' ] && [ -f 'intermediate.asn1.pem' ] ; then
    openssl verify  -CAfile ca.asn1.pem -untrusted intermediate.asn1.pem fullchain.asn1.pem       || echo "ERR: Original chain cannot be verified"
    openssl verify  -CAfile ca.asn1.pem -untrusted intermediate.asn1.pem results/fullchain.asn1.pem  || echo "ERR: Converted chain cannot be verified"
else
    #NOTE: as far as I know this does the same as above*
    #   *This command is only problematic if an adversary could trivially inject their on self-signed intermediate cert
    #   See: https://mail.python.org/pipermail/cryptography-dev/2016-August/000676.html
    #   -> tl;dr remember to set intermediate certificates as -untrusted, otherwise an arbitrary _self-signed_ intermediate cert
    #       will be accepted.
    #echo "Could not find 'ca.asn1.pem' and/or 'intermediate.asn1.pem'"
    openssl verify  -CAfile fullchain.asn1.pem fullchain.asn1.pem            || echo "ERR: Original chain cannot be verified"
    openssl verify  -CAfile results/fullchain.asn1.pem results/fullchain.asn1.pem  || echo "ERR: Converted chain cannot be verified"
fi
echo


#NOTE: the full chain of course needs to be given to OpenSSL when verifying,
#       e.g. even if you explicitly trust intermediate cert it still needs the CA to verify the chain.
#       However in my case (Ubuntu), OpenSSL already trusted a wide number of CAs received from Mozilla, see below.
#       Run: openssl version -d
#       This shows OPENSSLDIR which in my case were /usr/lib/ssl -> /etc/ssl/certs -> /usr/share/ca-certificates/mozilla
#       Therefore as long as the CA is located herein it needs not be specified in the command above.
