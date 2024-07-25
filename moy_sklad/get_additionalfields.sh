#!/bin/bash
#
#https://img.merlion.ru/items/1174212_v05_m.jpg
source ../.config

curl -s -X GET  https://api.moysklad.ru/api/remap/1.2/entity/product/metadata/attributes \
    -H "Accept-Encoding: gzip" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MY_SKLAD_TOKEN}" \
    -o output.gzip

