#!/bin/sh

# Having issues getting the ns-corp VPN to work on my mackbook
# Oracle Linux seems to have an older version open OpenSSL that will
# allow access.
# This is hopefully a temporary work around for December 2019.
#
# Start up corp vpn on Oracle Linux
# Start a SOCKSv5 Proxy
##ssh -D 3129 -f -C -q -N mrex@ol (I like to see the shell connect)
ssh -D 3129 -C -q -N mrex@ol
# Set the browser to use the Socks V5 Proxy (foxyproxy understands SOCKS5, point to localhost:3129)
# optionally tell GIT to use it: https://stackoverflow.com/questions/15227130/using-a-socks-proxy-with-git-for-the-http-transport
#
#### git config --global http.https://mrex@nacl-c001.adm.svale.netledger.com/ socks5://127.0.0.1:3129
# Actually just uncomment stanza in ~/.gitconfig
## UNDO: git config --unset http.https://mrex@nacl-c001.adm.svale.netledger.com/
# As a shell variable: ALL_PROXY=socks5://127.0.0.1:3129
#
# Make sure nacl-c001.adm.svale.netledger.com is in /etc/hosts
