#!/bin/bash
#

source /root/merlion_sync/.config

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

FILE_PART='get_items_properties'


# Items Array
ITEMS=`$MYSQL_CMD "SELECT DISTINCT no FROM Items_avail;"`

# Truncate tables
$MYSQL_CMD "TRUNCATE TABLE req_items_properties;"

# Make requests and insert them to mysql
for i in ${ITEMS[@]}; do
    REQ=`cat ${WORKDIR}/req.xml.template | sed "s/Order/${i}/g"`
    $MYSQL_CMD "INSERT INTO req_items_properties(no, request_xml) VALUES ('${i}','${REQ}');"
done
