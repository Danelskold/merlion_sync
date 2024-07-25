#!/bin/bash
#
source ../.config
source ../.functions

curl -s -X GET ${SKLAD_URL}/product \
    -H "Accept-Encoding: gzip" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MY_SKLAD_TOKEN}" \
    -o output.gzip
