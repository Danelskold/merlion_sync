#!/bin/bash
#
source ../.config
source ../.functions

curl -s -X GET https://api.moysklad.ru/api/remap/1.2/entity/counterparty \
    -H "Accept-Encoding: gzip" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MY_SKLAD_TOKEN}" \
    -o output.gzip
