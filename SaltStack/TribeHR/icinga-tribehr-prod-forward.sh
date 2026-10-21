#/bin/sh

#When we have local access
# ssh -NT -L 8080:10.48.49.242:80 root@129.213.58.215

# From Jumphost in sc8
#ssh -NT -L 8080:10.48.49.242:80 -R 8081:10.48.49.240:8080 172.17.42.201
ssh -A -t ocitribe -L 8080:localhost:8080 ssh -A -t ociprod -L 8080:localhost:8080 ssh -A -t 10.48.49.242 -L 8080:localhost:80
