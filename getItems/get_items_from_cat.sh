#!/bin/bash
#

source /root/merlion_sync/.config

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

GET_CAT_L3=`$MYSQL_CMD "SELECT root_cat FROM categories_level3;"`

FILE_PART='get_items_fromcategory'

# Truncate tables
$MYSQL_CMD "TRUNCATE TABLE req_items;"

# Make requests and insert them to mysql
for i in ${GET_CAT_L3[@]}; do
    REQ=`cat ${WORKDIR}/req.xml.template | sed "s/Order/${i}/g"`
    $MYSQL_CMD "INSERT INTO req_items(no, request_xml) VALUES ('${i}','${REQ}');"
done

# Download from merlion
for a in ${GET_CAT_L3[@]}; do
    # Generate request_xml
    $MYSQL_CMD "SELECT DISTINCT request_xml from req_items WHERE no = '$a';" > /tmp/req-${FILE_PART}-${a}.xml

    # Request to API
    curl -s -u "$AUTH" \
        --header "Content-Type: text/xml;charset=UTF-8" \
        --header "SOAPAction: https://apitest.merlion.com/dl/mlservice3#getItems" \
        --data @/tmp/req-${FILE_PART}-${a}.xml \
        -o /tmp/resp-${FILE_PART}-${a}.xml \
        $API_URL

    # Sleep for anti DOS
   sleep 0.2

    # Clear tmp files
    cat /tmp/resp-${FILE_PART}-${a}.xml | yq -p=xml -o=json > /tmp/resp-${FILE_PART}-${a}.json
    rm /tmp/resp-${FILE_PART}-${a}.xml
    rm /tmp/req-${FILE_PART}-${a}.xml

    for i in `ls /tmp/resp-${FILE_PART}-*.json`; do

        ARRAY_ELEMENTS=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item"  | grep '"No":' | wc -l`
        COUNT=0

        while [ $COUNT -lt "${ARRAY_ELEMENTS}" ]; do
            NO=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"No":' | awk -F '"' '{print $4}'`
            # removing first and last " remove last , remove slash near hdd "
            NAME=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Name":' | awk -F ':' '{print $2}' | sed -e 's/^."//' -e 's/.$//' -e 's/.$//' -e 's#/#\\/#g'`
            BRAND=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Brand":' | awk -F '"' '{print $4}'`
            VENDOR_PART=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Vendor_part":' | awk -F '"' '{print $4}'`
            EOL=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"EOL"' | awk -F '"' '{print $4}'`
            WARRANTY=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Warranty":' | awk -F '"' '{print $4}'`
            WEIGHT=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Weight":' | awk -F '"' '{print $4}'`
            VOLUME=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Volume":' | awk -F '"' '{print $4}'`
            MIN_PACKAGED=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Min_Packaged":' | awk -F '"' '{print $4}'`
            GROUP_NAME1=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"GroupName1":' | awk -F '"' '{print $4}'`
            GROUP_NAME2=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"GroupName2":' | awk -F '"' '{print $4}'`
            GROUP_NAME3=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"GroupName3":' | awk -F '"' '{print $4}'`
            GROUP_CODE1=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"GroupCode1":' | awk -F '"' '{print $4}'`
            GROUP_CODE2=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"GroupCode2":' | awk -F '"' '{print $4}'`
            GROUP_CODE3=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"GroupCode3":' | awk -F '"' '{print $4}'`
            ISBUNDLE=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"IsBundle":' | awk -F '"' '{print $4}'`
            LTM=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Last_time_modified":' | awk -F '"' '{print $4}'`
            VAT=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"VAT"' | awk -F '"' '{print $4}'`
            ISNEW=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"VAT":' | awk -F '"' '{print $4}'`
            LENGTH=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Length":' | awk -F '"' '{print $4}'`
            WIDTH=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Width":' | awk -F '"' '{print $4}'`
            HEIGHT=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Height":' | awk -F '"' '{print $4}'`
            PACKAGED=`cat $i | jq ".Envelope.Body.getItemsResponse.getItemsResult.item[${COUNT}]" | grep '"Packaged":' | awk -F '"' '{print $4}'`


            $MYSQL_CMD  "INSERT INTO \`items\`(\`no\`, \`Name\`, \`Brand\`, \`Vendor_part\`, \`EOL\`, \`Warranty\`, \`Weight\`, \`Volume\`, \`Min_Packaged\`, \`GroupName1\`, \`GroupName2\`, \
                             \`GroupName3\`, \`GroupCode1\`, \`GroupCode2\`, \`GroupCode3\`, \`IsBundle\`, \`Last_time_modified\`, \`VAT\`, \`IsNew\`, \`Length\`, \`Width\`, \`Height\`, \`Packaged\`, \`is_updated\`) \
                             SELECT '${NO}','${NAME}','${BRAND}','${VENDOR_PART}','${EOL}','${WARRANTY}','${WEIGHT}','${VOLUME}','${MIN_PACKAGED}','${GROUP_NAME1}','${GROUP_NAME2}','${GROUP_NAME3}','${GROUP_CODE1}', \
                            '${GROUP_CODE2}','${GROUP_CODE3}','${ISBUNDLE}','${LTM}','${VAT}','${ISNEW}','${LENGTH}','${WIDTH}','${HEIGHT}','${PACKAGED}', '1'  FROM DUAL WHERE NOT EXISTS(SELECT * FROM items WHERE no = '${NO}');"

#	    $MYSQL_CMD "UPDATE items SET no='${NO}', Name='${NAME}', Brand='${BRAND}', Vendor_part='${VENDOR_PART}',EOL='${EOL}',Warranty='${WARRANTY}',Weight='${WEIGHT}',Volume='${VOLUME}',Min_Packaged='${MIN_PACKAGED}', \
#	    GroupName1='${GROUP_NAME1}',GroupName2='${GROUP_NAME2}',GroupName3='${GROUP_NAME3}',GroupCode1='${GROUP_CODE1}',GroupCode2='${GROUP_CODE2}',GroupCode3='${GROUP_CODE3}',IsBundle='${ISBUNDLE}',Last_time_modified='${LTM}', \
#	    VAT='${VAT}', IsNew='${ISNEW}',Length='${LENGTH}',Width='${WIDTH}',Height='${HEIGHT}',Packaged='${PACKAGED}',is_updated='1' WHERE no = '${NO}';"

            COUNT=$(( $COUNT + 1 ))
        done

done

rm /tmp/resp-${FILE_PART}-${a}.json

done
