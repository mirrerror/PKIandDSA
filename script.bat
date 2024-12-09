@echo off

set "PKIPath=D:\PKIandDSA"
set "RootCAKey=%PKIPath%\rootCA.key"
set "RootCACert=%PKIPath%\rootCA.crt"
set "UserKey=%PKIPath%\user.key"
set "UserCSR=%PKIPath%\user.csr"
set "UserCert=%PKIPath%\user.crt"
set "SignatureFile=%PKIPath%\signature.bin"
set "FileToSign=%PKIPath%\file.txt"
set "UserPublicKey=%PKIPath%\user_pubkey.pem"

if not exist "%PKIPath%" (
    mkdir "%PKIPath%"
)

if not exist "%RootCAKey%" (
    echo Generating Root CA private key...
    openssl genrsa -out "%RootCAKey%" 4096
)

if not exist "%RootCACert%" (
    echo Creating self-signed Root CA certificate...
    openssl req -x509 -new -nodes -key "%RootCAKey%" -sha256 -days 3650 -out "%RootCACert%" ^
        -subj "/C=US/ST=California/L=SanFrancisco/O=MyOrganization/CN=MyRootCA"
)

if not exist "%UserKey%" (
    echo Generating user private key...
    openssl genrsa -out "%UserKey%" 2048
)

if not exist "%UserCSR%" (
    echo "Creating Certificate Signing Request (CSR) for user..."
    openssl req -new -key "%UserKey%" -out "%UserCSR%" ^
        -subj "/C=US/ST=California/L=SanFrancisco/O=UserOrganization/CN=User"
)

if not exist "%UserCert%" (
    echo Signing user certificate with Root CA...
    openssl x509 -req -in "%UserCSR%" -CA "%RootCACert%" -CAkey "%RootCAKey%" -CAcreateserial -out "%UserCert%" -days 365 -sha256
)

if not exist "%FileToSign%" (
    echo This is a test file for PKI signing. > "%FileToSign%"
)

echo Signing file: "%FileToSign%"...
openssl dgst -sha256 -sign "%UserKey%" -out "%SignatureFile%" "%FileToSign%"

echo Extracting public key from user certificate...
openssl x509 -in "%UserCert%" -pubkey -noout > "%UserPublicKey%"

echo Verifying signature for file: "%FileToSign%"...
openssl dgst -sha256 -verify "%UserPublicKey%" -signature "%SignatureFile%" "%FileToSign%"

echo Script has completed its execution successfully!
pause