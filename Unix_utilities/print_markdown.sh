#!/usr/bin/bash
# So I do not have to look at how to print markdown every time

#$FILE=$1

#echo "/usr/bin/markdown $1 | /usr/bin/iconv -f utf-8 -t iso-8859-1 | html2ps | lp -o sides=two-sided-long-edge"
/usr/bin/markdown $1 | /usr/bin/iconv -f utf-8 -t iso-8859-1 | html2ps | lp -o sides=two-sided-long-edge
