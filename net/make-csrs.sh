#!/bin/sh
# Source: https://confluence.corp.netsuite.com/display/~gmorrison/Internal+Certificate+Authority

while [ "$1" = "-v" -a "$#" -gt 2 ]; do
    vhosts="${vhosts},DNS:$2"
    shift 2
done
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 [-v vip] host ..."
    exit 1
fi
 
read -s -p "Keystore password: " pwd; echo
read -s -p "Keystore password (confirm): " pwdconf; echo
if [ "$pwd" != "$pwdconf" ]; then
    echo "Passwords do not match"
    exit 1
fi
 
for host in "$@"; do
    san="SAN=DNS:${host}${vhosts}"
    keytool -keystore "${host}.jks" -storepass "$pwd" -alias "$host" \
        -genkeypair -keypass "$pwd" -keyalg rsa -dname "cn=${host}" -ext "$san"
    keytool -keystore "${host}.jks" -storepass "$pwd" -alias "$host" \
        -certreq -file "${host}.csr" -ext "$san"
done
