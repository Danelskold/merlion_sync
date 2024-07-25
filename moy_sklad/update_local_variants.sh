#!/bin/bash
#

source ../.config
source ../.functions

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

FILE_PART='add_charact_msklad'

#cat ${WORKDIR}/characteristics.json | jq '.[]' | jq  '.id as $ID | .name as $NAME | "\($ID);\($NAME)"'
cat ${WORKDIR}/characteristics.json | jq '.characteristics[]' | jq  '.id as $ID | .name as $NAME | "\($ID);\($NAME)"' > /tmp/${FILE_PART}_list


#$MYSQL_CMD "SELECT DISTINCT `property_id` FROM `items_properties` WHERE `value` = 'Разрешение основного экрана, горизонтальное';"

FILE="cat /tmp/${FILE_PART}_list"
        $FILE | \
        while read CMD; do
            UUID=`echo $CMD | awk -F ';' '{print $1}' | sed -e 's/^.//g'`
	    NAME="`echo $CMD | awk -F ';' '{print $2}' | sed -e 's/.$//g'`"
	    ML=`$MYSQL_CMD "SELECT DISTINCT property_id FROM items_properties WHERE value = '${NAME}';"`
		for i in ${ML[@]}; do
		    $MYSQL_CMD "INSERT INTO \`msklad_character\`(\`ml_prop_id\`, \`msklad_uuid\`, \`name\`) VALUES ('${i}','${UUID}','${NAME}');"
		done

        done
