#!/bin/bash -x
#

source ../.config
source ../.functions

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

FILE_PART='add_characteristics'

# Category
ML=ML010201

# Values array
$MYSQL_CMD "SELECT DISTINCT value FROM items_properties;" | sed -e 's/\"/\\\\"/g' -e 's/\//\\\//g' > /tmp/${FILE_PART}_values


# Make requests and insert them to mysql
echo '[' > ${WORKDIR}/values.json
FILE="cat /tmp/${FILE_PART}_values"
    $FILE | \
    while read VALUE; do
	echo "{ \"name\": \"${VALUE}\" }," >>  ${WORKDIR}/values.json
    done

sed -i '$ s/\}\,/\}/g' ${WORKDIR}/values.json
echo ']' >>  ${WORKDIR}/values.json

curl -s -X POST  "https://api.moysklad.ru/api/remap/1.2/entity/variant/metadata/characteristics" \
        -H "Accept-Encoding: gzip" \
        -H "Authorization: Bearer ${MY_SKLAD_TOKEN}" \
        -H "Content-Type: application/json" \
        -o output.gzip \
        -d "@${WORKDIR}/values.json"

rm /tmp/${FILE_PART}_values
rm ${WORKDIR}/values.json
