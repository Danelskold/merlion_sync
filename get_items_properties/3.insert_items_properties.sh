#!/bin/bash -x
#

source /root/merlion_sync/.config

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

FILE_PART='get_items_properties'


# Items Array
ITEMS=`$MYSQL_CMD "SELECT DISTINCT no FROM ${TBL_ITM_AVAILIABILITY};"`

# Truncate tables
#$MYSQL_CMD "TRUNCATE TABLE ${TBL_REQ_ITMS_PROPERTIES};"

# Make requests and insert them to mysql
#for i in ${ITEMS[@]}; do
#    REQ=`cat ${WORKDIR}/req.xml.template | sed "s/Order/${i}/g"`
#    $MYSQL_CMD "INSERT INTO ${TLB_REQ_ITM_AVAILIABILITY}(no, request_xml) VALUES ('${i}','${REQ}');"
#done

# | jq '.Envelope.Body.getItemsPropertiesResponse.getItemsPropertiesResult.item[]' | jq '.No as $NO | .PropertyID as $PID | .PropertyName as $PN | "\($NO);\($PID);\($PN)"'

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
    PROPERTY_COUNT=$(echo $NUMBERS | wc -l)

    cat /tmp/resp-${FILE_PART}-${i}.json | jq '.Envelope.Body.getItemsPropertiesResponse.getItemsPropertiesResult.item[]' | jq '.PropertyID as $PID | .Value as $VL | "\($PID);\($VL)"' | \
    sed -e 's/^.//g' -e 's/.$//g' > /tmp/tmp_${i}
    FILE="cat /tmp/tmp_${i}"
    $FILE | \
    while read CMD; do
	OPT_PID=`echo $CMD | awk -F ';' '{print $1}'`
	OPT_VALUE=`echo $CMD | awk -F ';' '{print $2}'`
	#echo $NO
	#echo $OPT_PID
	#echo $OPT_VALUE
	$MYSQL_CMD "INSERT INTO \`items_properties\`(\`no\`, \`property_id\`, \`value\`) VALUES ('${NO}','${OPT_PID}','${OPT_VALUE}');"
    done
    rm /tmp/tmp_${i}

    rm /tmp/resp-${FILE_PART}-${i}.json
done
