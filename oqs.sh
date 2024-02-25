#! /bin/bash

CARBON_HOME=/Users/udarapathum/src/wso2/wso2is-7.0.0
OPENSSL_CONFIG=$CARBON_HOME/bin
OPENSSL_MODULES=$CARBON_HOME/lib

OPENSSL_VERSION=3.2.1
APR_VERSION=1.7.4
TCNATIVE_VERSION=1.3.0

CURRENT_DIR=$(pwd)
OPENSSL_INSTALL=$CURRENT_DIR/build/openssl
APR_INSTALL=$CURRENT_DIR/build/apr


# ----------- Build static version of OpenSSL 3.x.x -----------

if [ -f openssl-$OPENSSL_VERSION.tar.gz ]; then
    echo "File exists"
else
    echo "Downloading openssl-$OPENSSL_VERSION source code..."
    wget https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
fi
rm -rf openssl-$OPENSSL_VERSION
tar -xvf openssl-$OPENSSL_VERSION.tar.gz
cd openssl-$OPENSSL_VERSION

./Configure --prefix=$OPENSSL_INSTALL  no-shared -fPIC --openssldir=$OPENSSL_CONFIG
make && make install_sw

# ----------- Install ops provider for OpenSSL -----------

export OPENSSL_INSTALL=$OPENSSL_INSTALL
cd $CURRENT_DIR
rm -rf oqs-provider
git clone -b main https://github.com/open-quantum-safe/oqs-provider.git
cd oqs-provider

./scripts/fullbuild.sh
cmake --install _build

cp $OPENSSL_INSTALL/lib/ossl-modules/oqsprovider.dylib $OPENSSL_MODULES

# ----------- Enable oqs provider in OpenSSL -----------

# Copy the openssl.cnf file
cp $CURRENT_DIR/openssl.cnf $OPENSSL_CONFIG
cd $OPENSSL_CONFIG
# Replace the placeholder inside the file with the actual path
sed -i '' "s|%CARBON_HOME%|$CARBON_HOME|g" openssl.cnf


# ----------- Build static version of APR 1.6.3 or later -----------

cd $CURRENT_DIR
if [ -f apr-$APR_VERSION.tar.gz ]; then
    echo "File exists"
else
    echo "Downloading apr-$APR_VERSION source code..."
    wget https://dlcdn.apache.org//apr/apr-$APR_VERSION.tar.gz
fi
rm -rf apr-$APR_VERSION
tar -xvf apr-$APR_VERSION.tar.gz
cd apr-$APR_VERSION

./configure --prefix=$APR_INSTALL
make && make install

# ----------- Ensure the static APR library is used -----------

Check if the file exists
apr_file_path="$APR_INSTALL/lib/libapr-1.la"
if [ -e "$apr_file_path" ]; then
    # Backup the file
    cp "$apr_file_path" "$apr_file_path.bak"

    # Comment or delete the specified sections using awk
    awk '/dlname=/ {$0="#"$0} /library_names=/ {$0="#"$0} {print}' "$apr_file_path" > "$apr_file_path.temp"
    mv "$apr_file_path.temp" "$apr_file_path"

    echo "Sections in libapr-1.la edited successfully."
else
    echo "Error: libapr-1.la file not found in $APR_INSTALL/lib."
fi



# ----------- Build tc-native -----------

cd $CURRENT_DIR
if [ -f tomcat-native-$TCNATIVE_VERSION-src.tar.gz ]; then
    echo "File exists"
else
    echo "Downloading tomcat-native-$TCNATIVE_VERSION source code..."
    wget https://dlcdn.apache.org/tomcat/tomcat-connectors/native/$TCNATIVE_VERSION/source/tomcat-native-$TCNATIVE_VERSION-src.tar.gz
fi

tar -xvf tomcat-native-$TCNATIVE_VERSION-src.tar.gz
cd tomcat-native-$TCNATIVE_VERSION-src/native
./configure --with-apr=$APR_INSTALL --with-ssl=$OPENSSL_INSTALL --prefix=$CARBON_HOME
make && make install