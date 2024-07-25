#!/bin/bash
#

source /root/merlion_sync/.config

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

GET_ROOT_ID=`$MYSQL_CMD "SELECT id FROM root_category;"`

FILE_PART='getCatalog'

# Truncate tables
$MYSQL_CMD "TRUNCATE TABLE req_cat_level2;"
$MYSQL_CMD "TRUNCATE TABLE req_cat_level3;"

# Make requests for level 2 and insert them to mysql
for i in ${GET_ROOT_ID[@]}; do
    REQ=`cat ${WORKDIR}/req.xml.template | sed "s/Order/${i}/g"`
    $MYSQL_CMD "INSERT INTO req_cat_level2(no, request_xml) VALUES ('${i}','${REQ}');"
done

addCategoryLevel_2(){
# Add level 2 categoryies
for i in ${GET_ROOT_ID[@]}; do
    # Generate request_xml
    $MYSQL_CMD "SELECT DISTINCT request_xml from req_cat_level2 WHERE no = '${i}';" > /tmp/req-${FILE_PART}-${i}.xml

    # Request to API
    curl -s -u "$AUTH" \
        --header "Content-Type: text/xml;charset=UTF-8" \
        --header "SOAPAction: https://apitest.merlion.com/dl/mlservice3#getCatalog" \
        --data @/tmp/req-${FILE_PART}-${i}.xml \
        -o /tmp/resp-${FILE_PART}-${i}.xml \
        $API_URL
    # Sleep for anti DOS
    sleep 0.5

    cat /tmp/resp-${FILE_PART}-${i}.xml | yq -p=xml -o=json > /tmp/resp-${FILE_PART}-${i}.json
    rm /tmp/resp-${FILE_PART}-${i}.xml
    rm /tmp/req-${FILE_PART}-${i}.xml

    # Make viriables from json
    JSON_OUT=$(cat /tmp/resp-${FILE_PART}-${i}.json | jq '.Envelope.Body.getCatalogResponse.getCatalogResult.item[]')

    # Make only ProductID and Property ID in text file
    echo $JSON_OUT | jq '.ID as $ID | .ID_PARENT as $IDP | .Description as $DESCR | "\($ID);\($IDP);\($DESCR)"' | \
    sed -e 's/^.//g' -e 's/.$//g' > /tmp/tmp_${i}

    # Read file by line. Add categories
    FILE="cat /tmp/tmp_${i}"
    $FILE | \

    while read CMD; do
        ID=$(printf $CMD | awk -F ';' '{print $1}')
        PARENT_ID=$(printf $CMD | awk -F ';' '{print $2}')
	DESCRIPTION=$(echo $CMD | awk -F ';' '{print $3}' | sed -e 's/\\"/"/g')

	# Insert categories if it deleted
	$MYSQL_CMD "INSERT INTO categories_level2 (root_cat, category_id, description) SELECT '${PARENT_ID}', '${ID}', '${DESCRIPTION}' FROM DUAL WHERE NOT EXISTS(SELECT * FROM categories_level2 WHERE category_id = '${ID}');"

	# Update work
        # $MYSQL_CMD "UPDATE categories_level2 SET root_cat = '${PARENT_ID}', category_id = '${ID}', description = '${DESCRIPTION}' WHERE category_id = '${ID}';"

    done
    rm /tmp/tmp_${i}
    rm /tmp/resp-${FILE_PART}-${i}.json
done
}
####################### This for level 3

addCategoryLevel_2(){

GET_CAT_LEVEL2=`$MYSQL_CMD "SELECT category_id FROM categories_level2;"`

# Make requests for level 3 and insert them to mysql
for i in ${GET_CAT_LEVEL2[@]}; do
    REQ=`cat ${WORKDIR}/req.xml.template | sed "s/Order/${i}/g"`
    $MYSQL_CMD "INSERT INTO req_cat_level3(no, request_xml) VALUES ('${i}','${REQ}');"
done

# Add level 3 categoryies
for i in ${GET_CAT_LEVEL2[@]}; do
    # Generate request_xml
    $MYSQL_CMD "SELECT DISTINCT request_xml from req_cat_level3 WHERE no = '${i}';" > /tmp/req-${FILE_PART}-${i}.xml

    # Request to API
    curl -s -u "$AUTH" \
        --header "Content-Type: text/xml;charset=UTF-8" \
        --header "SOAPAction: https://apitest.merlion.com/dl/mlservice3#getCatalog" \
        --data @/tmp/req-${FILE_PART}-${i}.xml \
        -o /tmp/resp-${FILE_PART}-${i}.xml \
        $API_URL
    # Sleep for anti DOS
    sleep 0.5

    cat /tmp/resp-${FILE_PART}-${i}.xml | yq -p=xml -o=json > /tmp/resp-${FILE_PART}-${i}.json
    rm /tmp/resp-${FILE_PART}-${i}.xml
    rm /tmp/req-${FILE_PART}-${i}.xml

    # Make viriables from json
    JSON_OUT=$(cat /tmp/resp-${FILE_PART}-${i}.json | jq '.Envelope.Body.getCatalogResponse.getCatalogResult.item[]')

    # Make only ProductID and Property ID in text file
    echo $JSON_OUT | jq '.ID as $ID | .ID_PARENT as $IDP | .Description as $DESCR | "\($ID);\($IDP);\($DESCR)"' | \
    sed -e 's/^.//g' -e 's/.$//g' > /tmp/tmp_${i}

    # Read file by line. Add categories
    FILE="cat /tmp/tmp_${i}"
    $FILE | \

    while read CMD; do
        ID=$(printf $CMD | awk -F ';' '{print $1}')
        PARENT_ID=$(printf $CMD | awk -F ';' '{print $2}')
        DESCRIPTION=$(echo $CMD | awk -F ';' '{print $3}' | sed -e 's/\\"/"/g')
	if [ "$ID" = "null" ]; then
            echo "Nothing to add to mysql"
	else
	    # Insert categories if it deleted
 	    $MYSQL_CMD "INSERT INTO categories_level3 (category_id, root_cat, description) SELECT '${ID}', '${PARENT_ID}', '${DESCRIPTION}' FROM DUAL WHERE NOT EXISTS(SELECT * FROM categories_level2 WHERE category_id = '${ID}');"
	    echo $ID $PARENT_ID $DESCRIPTION
	fi

    done
    rm /tmp/tmp_${i}
    rm /tmp/resp-${FILE_PART}-${i}.json

#sleep 10
done
}

addCategoryLevel_2
