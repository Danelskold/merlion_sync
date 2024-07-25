#!/bin/bash
#

source /root/merlion_sync/.config

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

MYSQL_CMD="/usr/bin/mysql -u $MYSQL_USER -p${MYSQL_PASS} -D $MYSQL_DB -h $MYSQL_HOST --silent --raw -e"

FILE_PART='get_items_avail'


# Items Array
ITEMS=`$MYSQL_CMD "SELECT DISTINCT no FROM items;"`

# Truncate tables
$MYSQL_CMD "TRUNCATE TABLE req_items_avail;"

# Make requests and insert them to mysql
for i in ${ITEMS[@]}; do
    REQ=`cat ${WORKDIR}/req.xml.template | sed "s/Order/${i}/g"`
    $MYSQL_CMD "INSERT INTO req_items_avail(no, request_xml) VALUES ('${i}','${REQ}');"
done

# Download from merlion
for i in ${ITEMS[@]}; do
    # Generate request_xml
    $MYSQL_CMD "SELECT DISTINCT request_xml from req_items_avail WHERE no = $i;" > /tmp/req-${FILE_PART}-${i}.xml

    # Request to API
    curl -s -u "$AUTH" \
        --header "Content-Type: text/xml;charset=UTF-8" \
        --header "SOAPAction: https://apitest.merlion.com/dl/mlservice3#getItems" \
        --data @/tmp/req-${FILE_PART}-${i}.xml \
        -o /tmp/resp-${FILE_PART}-${i}.xml \
        $API_URL

    # Anti DDOS
    sleep 0.1

    cat /tmp/resp-${FILE_PART}-${i}.xml | yq -p=xml -o=json > /tmp/resp-${FILE_PART}-${i}.json
    rm /tmp/resp-${FILE_PART}-${i}.xml
    rm /tmp/req-${FILE_PART}-${i}.xml

    # Make viriables from json
    #No=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"No":' | awk -F '"' '{print $4}'`
    No=$i
    PriceClient=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"PriceClient":' | awk -F '"' '{print $4}'`
    PriceClient_RG=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"PriceClient_RG":' | awk -F '"' '{print $4}'`
    PriceClient_MSK=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"PriceClient_MSK":' | awk -F '"' '{print $4}'`
    AvailableClient=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"AvailableClient":' | awk -F '"' '{print $4}'`
    AvailableClient_RG=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"AvailableClient_RG":' | awk -F '"' '{print $4}'`
    AvailableClient_MSK=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"AvailableClient_MSK":' | awk -F '"' '{print $4}'`
    AvailableExpected=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"AvailableExpected":' | awk -F '"' '{print $4}'`
    AvailableExpectedNext=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"AvailableExpectedNext":' | awk -F '"' '{print $4}'`
	#echo $AvailableExpectedNext
	if [ "${AvailableExpectedNext}" -eq "0" ]; then
	    DateExpectedNext='0'
	else
	    DateExpectedNext=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"DateExpectedNext":' | awk -F '"' '{print $4}'`
	fi
    RRP=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"RRP":' | awk -F '"' '{print $4}'`
    PriceClientRUB=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"PriceClientRUB":' | awk -F '"' '{print $4}'`
    PriceClientRUB_RG=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"PriceClientRUB_RG":' | awk -F '"' '{print $4}'`
    PriceClientRUB_MSK=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"PriceClientRUB_MSK":' | awk -F '"' '{print $4}'`
    Online_Reserve=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"Online_Reserve":' | awk -F '"' '{print $4}'`
    ReserveCost=`cat /tmp/resp-${FILE_PART}-${i}.json | jq ".Envelope.Body.getItemsAvailResponse.getItemsAvailResult.item" | grep '"ReserveCost":' | awk -F '"' '{print $4}'`


    # Get cur price
    IS_ITEM_AVAIL=`$MYSQL_CMD "SELECT no FROM Items_avail WHERE no='${i}';"`

    if [ ! -z "${IS_ITEM_AVAIL}" ]; then
        PRICE=`$MYSQL_CMD "SELECT DISTINCT PriceClient from Items_avail WHERE no='${i}';"`

    # Update only changed items
    $MYSQL_CMD "UPDATE Items_avail SET PriceClient='${PriceClient}', PriceClient_RG='${PriceClient_RG}', PriceClient_MSK='${PriceClient_MSK}', AvailableClient='${AvailableClient}', AvailableClient_RG='${AvailableClient_RG}', \
   	AvailableClient_MSK='${AvailableClient_MSK}',PriceClientRUB="${PriceClientRUB}",PriceClientRUB_RG="${PriceClientRUB_RG}",PriceClientRUB_MSK="${PriceClientRUB_MSK}",Online_Reserve='${Online_Reserve}', \
	ReserveCost='${ReserveCost}',is_updated='1' WHERE PriceClient!='${PRICE}' AND no='${i}';"

    else

    # Update all items
#    $MYSQL_CMD "UPDATE Items_avail SET no='${No}', PriceClient='${PriceClient}', PriceClient_RG='${PriceClient_RG}', PriceClient_MSK='${PriceClient_MSK}', AvailableClient='${AvailableClient}', \
#	AvailableClient_RG='${AvailableClient_RG}', AvailableClient_MSK='${AvailableClient_MSK}', AvailableExpected='${AvailableExpected}', AvailableExpectedNext='${AvailableExpectedNext}', \
#	DateExpectedNext="${DateExpectedNext}", RRP="${RRP}", PriceClientRUB="${PriceClientRUB}", PriceClientRUB_RG="${PriceClientRUB_RG}", PriceClientRUB_MSK="${PriceClientRUB_MSK}", \
#	Online_Reserve='${Online_Reserve}', ReserveCost='${ReserveCost}', is_updated='1' WHERE no='${No}';"

    $MYSQL_CMD "INSERT INTO Items_avail (no, PriceClient, PriceClient_RG, PriceClient_MSK, AvailableClient, AvailableClient_RG, AvailableClient_MSK, AvailableExpected, AvailableExpectedNext, \
			  DateExpectedNext, RRP, PriceClientRUB, PriceClientRUB_RG, PriceClientRUB_MSK, Online_Reserve, ReserveCost, is_updated) \
			  VALUES ('${No}','${PriceClient}','${PriceClient_RG}','${PriceClient_MSK}','${AvailableClient}','${AvailableClient_RG}','${AvailableClient_MSK}','${AvailableExpected}','${AvailableExpectedNext}', \
			  '${DateExpectedNext}','${RRP}','${PriceClientRUB}','${PriceClientRUB_RG}','${PriceClientRUB_MSK}','${Online_Reserve}','${ReserveCost}','0') \

 			  ON DUPLICATE KEY UPDATE no='${No}', PriceClient='${PriceClient}', PriceClient_RG='${PriceClient_RG}', PriceClient_MSK='${PriceClient_MSK}', AvailableClient='${AvailableClient}', \
		          AvailableClient_RG='${AvailableClient_RG}', AvailableClient_MSK='${AvailableClient_MSK}', AvailableExpected='${AvailableExpected}', AvailableExpectedNext='${AvailableExpectedNext}', \
		          DateExpectedNext="${DateExpectedNext}", RRP="${RRP}", PriceClientRUB="${PriceClientRUB}", PriceClientRUB_RG="${PriceClientRUB_RG}", PriceClientRUB_MSK="${PriceClientRUB_MSK}", \
		          Online_Reserve='${Online_Reserve}', ReserveCost='${ReserveCost}', is_updated='0';"
#	echo "Item ${i} added"
    fi


    rm /tmp/resp-${FILE_PART}-${i}.json
done

