#!/bin/bash
#
source ../.config
source ../.functions

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

curl -s -X GET ${SKLAD_URL}/productfolder \
    -H "Accept-Encoding: gzip" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MY_SKLAD_TOKEN}" \
    -o ${WORKDIR}/categories.gzip

cat ${WORKDIR}/categories.gzip | gunzip -c | jq '.rows[]' | jq '.id as $ID | .externalCode as $EXTC | .name as $NAME | "\($ID);\($EXTC);\($NAME)"' | \
    sed -e 's/^.//g' -e 's/.$//g' > ${WORKDIR}/moy_sklad_categories.txt
rm ${WORKDIR}/categories.gzip
