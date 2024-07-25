#!/bin/bash 
#

source /root/merlion_sync/.config

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

MYSQL_CMD="/usr/bin/mysql -u $MYSQL_USER -p${MYSQL_PASS} -D $MYSQL_DB -h $MYSQL_HOST --silent --raw -e"

FILE_PART='get_items_images'


# Items Array
ITEMS=`$MYSQL_CMD "SELECT no FROM items;"`

# Truncate tables
#$MYSQL_CMD "TRUNCATE TABLE req_items_images;"
#$MYSQL_CMD "TRUNCATE TABLE response_items_images;"

# Make requests and insert them to mysql
#for i in ${ITEMS[@]}; do
#    REQ=`cat ${WORKDIR}/req.xml.template | sed "s/Order/${i}/g"`
#    $MYSQL_CMD "INSERT INTO req_items_images(no, request_xml) VALUES ('${i}','${REQ}');"
#done

REQ=`$MYSQL_CMD "SELECT no FROM req_items_avail;"`

for i in ${REQ[@]}; do
    $MYSQL_CMD "SELECT request_xml from req_items_images WHERE no = $i;" > /tmp/req-${FILE_PART}-${i}.xml

	curl -s -u "$AUTH" \
	    --header "Content-Type: text/xml;charset=UTF-8" \
	    --header "SOAPAction: https://apitest.merlion.com/dl/mlservice3#getItemsImages" \
	    --data @/tmp/req-${FILE_PART}-${i}.xml \
	    -o /tmp/resp-${FILE_PART}-${i}.xml \
	    $API_URL

	sleep 0.5

	cat /tmp/resp-${FILE_PART}-${i}.xml | yq -p=xml -o=json > /tmp/resp-${FILE_PART}-${i}.json

	RESP_JSON=`cat /tmp/resp-${FILE_PART}-${i}.json`

       $MYSQL_CMD "INSERT INTO \`response_items_images\`(\`no\`, \`resp_json\`) VALUES ('${i}','${RESP_JSON}')"
	rm /tmp/resp-${FILE_PART}-${i}.json
	rm /tmp/resp-${FILE_PART}-${i}.xml
done

