#!/bin/sh
# Source: https://confluence.corp.netsuite.com/display/~gmorrison/Internal+Certificate+Authority

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 host ..."
    exit 1
fi
 
read -s -p "Keystore password: " pwd; echo
 
for host in "$@"; do
    host=${host%.crt}
    keytool -keystore "${host}.jks" -storepass "$pwd" -alias "$host" \
        -importcert -file "${host}.crt" -noprompt
done
