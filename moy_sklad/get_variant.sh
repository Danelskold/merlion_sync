#!/bin/bash
#
source ../.config

curl -s -X GET "https://api.moysklad.ru/api/remap/1.2/entity/variant" \
    -H "Accept-Encoding: gzip" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MY_SKLAD_TOKEN}" \
    -o output.gzip
