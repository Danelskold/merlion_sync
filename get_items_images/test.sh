#!/bin/bash 
#

source /root/merlion_sync/.config

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

MYSQL_CMD="/usr/bin/mysql -u $MYSQL_USER -p${MYSQL_PASS} -D $MYSQL_DB -h $MYSQL_HOST --silent --raw -e"

GET_CAT=`$MYSQL_CMD "SELECT category_id FROM categories_level3;"`

FILE_PART='get_items_images'

for i in $GET_CAT; do
    cat ${WORKDIR}/req.xml.template | sed "s/Order/${i}/g" > /tmp/req-${FILE_PART}-${i}.xml
done


for i in `ls /tmp/req-${FILE_PART}*.xml`; do
    CAT_ID=`basename $i | awk -F '-' '{print $3}' | awk -F '.' '{print $1}'`
	echo $CAT_ID

	curl -s -u "$AUTH" \
	    --header "Content-Type: text/xml;charset=UTF-8" \
	    --header "SOAPAction: https://apitest.merlion.com/dl/mlservice3#getItems" \
	    --data @${i} \
	    -o /tmp/resp-${FILE_PART}-${CAT_ID}.xml \
	    $API_URL

	sleep 0.5

	cat /tmp/resp-${FILE_PART}-${CAT_ID}.xml | yq -p=xml -o=json > /tmp/resp-${FILE_PART}-${CAT_ID}.json
	rm /tmp/resp-${FILE_PART}-${CAT_ID}.xml
done

