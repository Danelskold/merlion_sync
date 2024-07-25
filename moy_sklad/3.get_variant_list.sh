#!/bin/bash
#
source ../.config

curl -s -X GET "https://api.moysklad.ru/api/remap/1.2/entity/variant/metadata" \
    -H "Accept-Encoding: gzip" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MY_SKLAD_TOKEN}" \
    -o output.gzip

cat output.gzip | gunzip -c | jq '.characteristics[]' |  jq  '.id as $ID | .name as $NAME | "\($ID);\($NAME)"' > /tmp/moy_sklad_variants.txt

FILE="cat /tmp/moy_sklad_variants.txt"
        $FILE | \
        while read CMD; do
            UUID=`echo $CMD | awk -F ';' '{print $1}' | sed -e 's/^.//g'`
            NAME=`echo $CMD | awk -F ';' '{print $2}' | sed -e 's/.$//g'`
            #ML=`$MYSQL_CMD "SELECT DISTINCT property_id FROM items_properties WHERE value = '${NAME}';"`
            #$MYSQL_CMD "INSERT INTO \`msklad_characteristics\`( \`ml\`, \`uuid\`, \`name\`) VALUES ('${ML}','${UUID}','${NAME}');"
	    ML=`$MYSQL_CMD "SELECT DISTINCT property_id FROM items_properties WHERE value = '${NAME}';"`
                for i in ${ML[@]}; do
                    $MYSQL_CMD "INSERT INTO \`msklad_characteristics\`(\`ml\`, \`uuid\`, \`name\`) VALUES ('${i}','${UUID}','${NAME}');"
                done
        done
