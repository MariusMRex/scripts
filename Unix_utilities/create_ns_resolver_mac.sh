#!/bin/bash

for i in netledger.com corp.netsuite.com eng.netsuite.com
  do
    for j in `dig ${i} NS +short`
  do
    FOO=$(dig $j +short); [[ ! -z $FOO ]] && sudo sh -c "echo 'nameserver $FOO' >> /etc/resolver/${i}"
  done
done
