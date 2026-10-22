#!/bin/sh
#ssh -L 4050:10.0.0.149:22 marius@infra01.dc-1.uk.venda.com
# Chef Access in UAT
#ssh -L 4040:10.8.144.60:4040 marius@uat.dc-1.uk.venda.com
#ssh -L 4050:10.8.144.5:22 marius@uat.dc-1.uk.venda.com

# Chef API Access in UAT
#ssh -L 4050:10.8.144.60:4000 marius@uat.dc-1.uk.venda.com

# Forward ssh to uat-kvm01 on 4051, Chef-API on 4050 and HTTPS to uat-monitor01 nagios on 4430
ssh -L 4051:10.8.144.5:22 -L 4050:10.18.152.50:443 -L 4430:10.8.144.66:443 marius@uat.dc-1.uk.venda.com
