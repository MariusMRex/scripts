#!/bin/sh

# Access STM GUI (9090) via port 9999 in Openxtack POC environment
ssh -L 9999:127.0.0.1:9090  marius@10.199.55.42

