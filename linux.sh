#! /bin/bash

# OPENSSL_VERSION=3.2.1
# APR_VERSION=1.7.4
# TCNATIVE_VERSION=1.3.0

# GITHUB_WORKSPACE=$(pwd)
# OPENSSL_INSTALL=$GITHUB_WORKSPACE/build/openssl
# APR_INSTALL=$GITHUB_WORKSPACE/build/apr
# OUTPUT_DIR=$GITHUB_WORKSPACE/lib

# ----------- Build static version of OpenSSL 3.x.x -----------

mkdir -p $OUTPUT_DIR

echo "Downloading openssl-$OPENSSL_VERSION source code..."
wget https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
tar -xzf openssl-$OPENSSL_VERSION.tar.gz
cd openssl-$OPENSSL_VERSION

./Configure --prefix=$OPENSSL_INSTALL  no-shared -fPIC --openssldir=$OUTPUT_DIR
make && make install_sw


# ----------- Build static version of APR 1.6.3 or later -----------

cd $GITHUB_WORKSPACE
echo "Downloading apr-$APR_VERSION source code..."
wget https://dlcdn.apache.org//apr/apr-$APR_VERSION.tar.gz
tar -xzf apr-$APR_VERSION.tar.gz
cd apr-$APR_VERSION

./configure --prefix=$APR_INSTALL
make && make install

# Ensure the static APR library is used
# apr_file_path="$APR_INSTALL/lib/libapr-1.la"
# if [ -e "$apr_file_path" ]; then
#     # Backup the file
#     cp "$apr_file_path" "$apr_file_path.bak"
#     # Comment or delete the specified sections using awk
#     awk '/dlname=/ {$0="#"$0} /library_names=/ {$0="#"$0} {print}' "$apr_file_path" > "$apr_file_path.temp"
#     mv "$apr_file_path.temp" "$apr_file_path"
#     echo "Sections in libapr-1.la edited successfully."
# else
#     echo "Error: libapr-1.la file not found in $APR_INSTALL/lib."
# fi

# ----------- Build tc-native -----------

cd $GITHUB_WORKSPACE
echo "Downloading tomcat-native-$TCNATIVE_VERSION source code..."
wget https://dlcdn.apache.org/tomcat/tomcat-connectors/native/$TCNATIVE_VERSION/source/tomcat-native-$TCNATIVE_VERSION-src.tar.gz

tar -xzf tomcat-native-$TCNATIVE_VERSION-src.tar.gz
cd tomcat-native-$TCNATIVE_VERSION-src/native
./configure --with-apr=$APR_INSTALL --with-ssl=$OPENSSL_INSTALL --prefix=$GITHUB_WORKSPACE
make && make install

# ----------- Install ops provider for OpenSSL -----------

cd $GITHUB_WORKSPACE
git clone -b main https://github.com/open-quantum-safe/oqs-provider.git
cd oqs-provider

./scripts/fullbuild.sh
cmake --install _build

cp $OPENSSL_INSTALL/lib64/ossl-modules/oqsprovider.so $OUTPUT_DIR
