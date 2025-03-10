#!/bin/bash
#

source /root/merlion_sync/.config

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

FILE_PART='get_items_properties'


# Items Array
ITEMS=`$MYSQL_CMD "SELECT DISTINCT no FROM Items_avail;"`

# Truncate tables
$MYSQL_CMD "TRUNCATE TABLE item_properties_list;"
$MYSQL_CMD "TRUNCATE TABLE items_properties;"
$MYSQL_CMD "TRUNCATE TABLE req_items_properties;"

# Make requests and insert them to mysql
for i in ${ITEMS[@]}; do
    REQ=`cat ${WORKDIR}/req.xml.template | sed "s/Order/${i}/g"`
    $MYSQL_CMD "INSERT INTO req_items_properties(no, request_xml) VALUES ('${i}','${REQ}');"
done

# Download from merlion
for i in ${ITEMS[@]}; do
    # Generate request_xml
    $MYSQL_CMD "SELECT DISTINCT request_xml from req_items_properties WHERE no = $i;" > /tmp/req-${FILE_PART}-${i}.xml

    # Request to API
    curl -s -u "$AUTH" \
        --header "Content-Type: text/xml;charset=UTF-8" \
        --header "SOAPAction: https://apitest.merlion.com/dl/mlservice3#getItemsProperties" \
        --data @/tmp/req-${FILE_PART}-${i}.xml \
        -o /tmp/resp-${FILE_PART}-${i}.xml \
        $API_URL

    # Sleep for anti DOS
    sleep 0.2

    # Clear tmp files
    cat /tmp/resp-${FILE_PART}-${i}.xml | yq -p=xml -o=json > /tmp/resp-${FILE_PART}-${i}.json
    rm /tmp/resp-${FILE_PART}-${i}.xml
    rm /tmp/req-${FILE_PART}-${i}.xml

    # Make viriables from json
    NUMBERS=$(cat /tmp/resp-${FILE_PART}-${i}.json | jq '.Envelope.Body.getItemsPropertiesResponse.getItemsPropertiesResult.item[]')
    NO=$(echo $NUMBERS | jq '.No' | sed -e 's/^.//g' -e 's/.$//g' | tail -1)
    PROPERTY_COUNT=$(echo $NUMBERS | grep Value | wc -l)

    # Make only ProductID and Property ID in text file
    cat /tmp/resp-${FILE_PART}-${i}.json | jq '.Envelope.Body.getItemsPropertiesResponse.getItemsPropertiesResult.item[]' | jq '.PropertyID as $PID | .PropertyName as $PN | .Value as $VL | "\($PID);\($PN);\($VL)"' | \
    sed -e 's/^.//g' -e 's/.$//g' > /tmp/tmp_${i}

#    cat /tmp/resp-${FILE_PART}-${i}.json | jq '.Envelope.Body.getItemsPropertiesResponse.getItemsPropertiesResult.item[]' | jq '.PropertyID as $PID | .Value as $VL | "\($PID);\($VL)"' | \
#    sed -e 's/^.//g' -e 's/.$//g' > /tmp/tmp_2_${i}

    # Add properties to table
    FILE="cat /tmp/tmp_${i}"
    $FILE | \
    while read CMD; do
        OPT_PID=`echo $CMD | awk -F ';' '{print $1}'`
        OPT_VALUE=`echo $CMD | awk -F ';' '{print $2}'`
	OPT_NAME=`echo $CMD | awk -F ';' '{print $3}'`
        #echo $NO
        #echo $OPT_PID
        #echo $OPT_VALUE
        $MYSQL_CMD "INSERT INTO \`items_properties\`(\`no\`, \`property_id\`, \`property_name\`, \`value\`) VALUES ('${NO}','${OPT_PID}','${OPT_NAME}','${OPT_VALUE}');"
    done

    # Read file by line. Add properties list
#    FILE="cat /tmp/tmp_${i}"
#    $FILE | \

#    while read CMD; do
#	OPT_ID=$(echo $CMD | awk -F ';' '{print $1}')
#	OPT_NAME=$(echo $CMD | awk -F ';' '{print $2}')
#	$MYSQL_CMD "INSERT IGNORE INTO \`item_properties_list\`(\`no\`, \`description\`, \`propery_id\`) VALUES ('${NO}','${OPT_NAME}','${OPT_ID}');"
#    done

    rm /tmp/tmp_${i}
#    rm /tmp/tmp_2_${i}
    rm /tmp/resp-${FILE_PART}-${i}.json

done
