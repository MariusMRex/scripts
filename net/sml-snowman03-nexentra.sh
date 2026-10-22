#!/bin/sh

# Having issues getting to https://snowman03.of-1.uk.venda.com:2000/  This is a work-around.
ssh -L 2001:snowman03.of-1.uk.venda.com:2000 marius@venda-dev-proxy.corp.netledger.com
