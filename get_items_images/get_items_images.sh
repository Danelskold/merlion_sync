#!/bin/bash
#

source /root/merlion_sync/.config

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

FILE_PART='get_items_images'


# Items Array
ITEMS=`$MYSQL_CMD "SELECT DISTINCT no FROM ${TBL_ITMS};"`

# Truncate tables
#$MYSQL_CMD "TRUNCATE TABLE ${TBL_REQ_ITMS_IMAGES};"

# Make requests and insert them to mysql
#for i in ${ITEMS[@]}; do
#    REQ=`cat ${WORKDIR}/req.xml.template | sed "s/Order/${i}/g"`
#    $MYSQL_CMD "INSERT INTO ${TLB_REQ_ITM_AVAILIABILITY}(no, request_xml) VALUES ('${i}','${REQ}');"
#done

# Download from merlion
for i in ${ITEMS[@]}; do
    # Generate request_xml
    $MYSQL_CMD "SELECT DISTINCT request_xml from ${TBL_REQ_ITMS_IMAGES} WHERE no = $i;" > /tmp/req-${FILE_PART}-${i}.xml

    # Request to API
    curl -s -u "$AUTH" \
        --header "Content-Type: text/xml;charset=UTF-8" \
        --header "SOAPAction: https://apitest.merlion.com/dl/mlservice3#getItemsImages" \
        --data @/tmp/req-${FILE_PART}-${i}.xml \
        -o /tmp/resp-${FILE_PART}-${i}.xml \
        $API_URL

    # Sleep for anti DOS
    sleep 0.4
    cat /tmp/resp-${FILE_PART}-${i}.xml | yq -p=xml -o=json > /tmp/resp-${FILE_PART}-${i}.json
    rm /tmp/resp-${FILE_PART}-${i}.xml


    # Make viriables from json
    No=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsImagesResponse.getItemsImagesResult.item" | grep '"No":' | awk -F '"' '{print $4}' | head -1`
    ARRAY_VIEWTYPE=(`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsImagesResponse.getItemsImagesResult.item" | grep '"ViewType":' | awk -F ':' '{print $2}' | sed -e 's/^.//g' -e 's/^.//g' -e 's/.$//g' -e 's/.$//g'`)
    ARRAY_SIZETYPE=(`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsImagesResponse.getItemsImagesResult.item" | grep '"SizeType":' | awk -F ':' '{print $2}' | sed -e 's/^.//g' -e 's/^.//g' -e 's/.$//g' -e 's/.$//g'`)
    ARRAY_FILENAME=(`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsImagesResponse.getItemsImagesResult.item" | grep '"FileName":' | awk -F ':' '{print $2}' | sed -e 's/^.//g' -e 's/^.//g' -e 's/.$//g' -e 's/.$//g'`)
    ARRAY_CREATED=(`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsImagesResponse.getItemsImagesResult.item" | grep '"Created":' | awk -F ':' '{print $2}' | sed -e 's/^.//g' -e 's/^.//g' -e 's/.$//g' -e 's/.$//g'`)
    ARRAY_SIZE=(`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsImagesResponse.getItemsImagesResult.item" | grep '"Size":' | awk -F ':' '{print $2}' | sed -e 's/^.//g' -e 's/^.//g' -e 's/.$//g' -e 's/.$//g'`)
    ARRAY_WIDTH=(`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsImagesResponse.getItemsImagesResult.item" | grep '"Width":' | awk -F ':' '{print $2}' | sed -e 's/^.//g' -e 's/^.//g' -e 's/.$//g' -e 's/.$//g'`)
    ARRAY_HEIGHT=(`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsImagesResponse.getItemsImagesResult.item" | grep '"Height":' | awk -F ':' '{print $2}' | sed -e 's/^.//g' -e 's/^.//g' -e 's/.$//g' -e 's/.$//g'`)


        NUM=0
        while [ "${NUM}" -lt "${#ARRAY_HEIGHT[@]}" ]; do
	# Insert into database
         $MYSQL_CMD "INSERT INTO \`items_images\`(\`no\`, \`ViewType\`, \`SizeType\`, \`FileName\`, \`Created\`, \`Size\`, \`Width\`, \`Height\`) \
	 VALUES ('${No}','${ARRAY_VIEWTYPE[${NUM}]}','${ARRAY_SIZETYPE[${NUM}]}','${ARRAY_FILENAME[${NUM}]}','${ARRAY_CREATED[${NUM}]}','${ARRAY_SIZE[${NUM}]}', '${ARRAY_WIDTH[${NUM}]}', '${ARRAY_HEIGHT[${NUM}]}');"

	NUM=$(( $NUM + 1 ))
    done

    rm /tmp/resp-${FILE_PART}-${i}.json
done

