#!/bin/sh
# Original inspiration: https://photo.stackexchange.com/questions/99217/how-can-i-delete-files-previously-removed-from-darktable/99224#99224

# '-1' is rejected.
RATING='-1'

for f in `grep -l "xmp:Rating=\"${RATING}\"" *.xmp`
do
    rm ${f%.xmp}
    rm $f
done
