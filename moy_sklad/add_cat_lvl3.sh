#!/bin/bash
#
source ../.config
source ../.functions


#$MYSQL_CMD "SELECT t2.uuid, t1.* FROM categories_level2 as t1 JOIN msklad_cat as t2 ON t2.ml = t1.root_cat;"
#$MYSQL_CMD "SELECT t2.uuid, t1.* FROM categories_level2 as t1  LEFT JOIN msklad_cat as t2 ON t2.ml = t1.root_cat WHERE t2.uuid = 'UUID';"

UUIDS=$($MYSQL_CMD "SELECT uuid FROM msklad_cat_l2;")

for i in ${UUIDS[@]}; do
    $MYSQL_CMD "SELECT t2.uuid, t1.description FROM categories_level3 as t1 LEFT JOIN msklad_cat_l2 as t2 ON t2.ml = t1.root_cat WHERE t2.uuid = '${i}';" > $i

	FILE="cat $i"
	$FILE | \
	while read CMD; do
	    UUID=$(cat /proc/sys/kernel/random/uuid)
	    PARENT_UUID=`echo $CMD | awk '{print $1}'`
	    NAME=`echo $CMD | awk '{print $2, $3, $4, $5, $6, $7}'`
#	sleep 1
            cat mkchildgroup.json.template | sed -e "s/CHILDGROUPNAME/${NAME}/g" -e "s/PARENTGROUPUUID/${PARENT_UUID}/g" > ${UUID}.json
	done
rm $i
done

for i in `ls *.json`; do
curl -s -X POST ${SKLAD_URL}/productfolder \
    -H "Accept-Encoding: gzip" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${MY_SKLAD_TOKEN}" \
    -d @${i}
#echo $i
rm $i
done
