#!/bin/bash -x
#

source ../.config
source ../.functions

WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

FILE_PART='add_item_msklad'

# Category
ML=ML250106

# Items Array
#ITEMS=`$MYSQL_CMD "SELECT DISTINCT no FROM items WHERE GroupCode3 = '${ML}';"`
# Items available
ITEMS=`$MYSQL_CMD "SELECT DISTINCT t1.no FROM items AS t1 RIGHT JOIN Items_avail as t2 ON t2.no = t1.no WHERE t1.GroupCode3 = '${ML}' AND t2.PriceClient > 0;"`

PRODUCT_FOLDER=`$MYSQL_CMD "SELECT uuid FROM msklad_cat WHERE ml = '${ML}';"`

if [  -z "$PRODUCT_FOLDER" ]; then
    echo "Add product folder"
    exit 1;
fi

# Okruglenie
round() { echo $(printf %.$2f $(echo "scale=$2;(((10^$2)*$1)+0.5)/(10^$2)" | bc)); };

# Make requests and insert them to mysql
for i in ${ITEMS[@]}; do
	NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
	PRODUCT_NAME=$($MYSQL_CMD "SELECT Name from items WHERE no = '${i}';" | sed -e 's/"/\\\\"/g' -e 's#/#\\/#g' 2>&1)

	#sleep 2

	if [ "$?" -eq "1" ]; then
	    echo "Item with id: ${i} error, name ${PRODUCT_NAME}" >> $WORKDIR/items_with_errors.txt;
	fi

	# What item have error
        #if [ "$?" -eq "1" ]; then  echo "Item with id: ${i} error, name ${PRODUCT_NAME}" >> $WORKDIR/items_with_errors.txt  fi

	# | sed -e 's/\"/\\"/g' -e 's/\//\\//g' -e 's/(/\\(/g' -e 's/)/\\)/g' -e 's/\./\\./g')

	BUY_PRICE=$($MYSQL_CMD "SELECT DISTINCT PriceClientRUB from Items_avail WHERE no = '${i}'")

	BUY_PRICE_ROUND=$(round ${BUY_PRICE}/1+1 0)
	PERCENT=$(bc <<<"${BUY_PRICE_ROUND}*10/100")
	BUY_PRICE_ITOG=$((${BUY_PRICE_ROUND} + ${PERCENT}))

	MIN_PROF=$(bc <<<"${BUY_PRICE_ROUND}*5/100")
	ROZNICA_PRICE=$(( (${BUY_PRICE_ROUND} + ${PERCENT}) * 100 ))
	MIN_PRICE=$(( (${BUY_PRICE_ROUND} + ${MIN_PROF}) * 100 ))

	BUY_PRICE_ITOG=$(( ${BUY_PRICE_ROUND} * 100 ))

	PROPERTIES=`$MYSQL_CMD "SELECT DISTINCT property_id FROM items_properties WHERE no = '${i}';"`

	for p in ${PROPERTIES[@]}; do
	    $MYSQL_CMD "SELECT DISTINCT t1.msklad_uuid,';',t1.name,';',t2.property_name FROM msklad_character AS t1 RIGHT JOIN \
	        items_properties as t2 ON t2.property_id = t1.ml_prop_id WHERE t1.ml_prop_id = '${p}' AND t2.no = '${i}';"  >> /tmp/${FILE_PART}_${i}
	done

	# Starting create JSON
	cat ${WORKDIR}/additem_START.json.template | sed -e "s/PRODUCT_NAME/${PRODUCT_NAME}/g" -e "s/CODE/${i}/g" > /tmp/${FILE_PART}_${i}_test.json

	NUM=0
        while [ "${NUM}" -lt "10" ]; do
	LINE=$(( $NUM + 1 ))

		VARIANT_UUID=$(cat /tmp/${FILE_PART}_${i} | sed -n "${LINE}p" | awk -F ';' '{print $1}' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//')
		VARIANT_NAME=$(cat /tmp/${FILE_PART}_${i} | sed -n "${LINE}p" | awk -F ';' '{print $2}' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' -e 's/(/\\(/g' -e 's/)/\\)/g' -e 's#/#\\/#g')
		VARIANT_VAL=$(cat /tmp/${FILE_PART}_${i} | sed -n "${LINE}p" | awk -F ';' '{print $3}' | sed -e 's/"/\"/g' -e 's/\//\//g' -e 's/^[ \t]*//' -e 's/[ \t]*$//'  -e 's#/#\\\\/#g')

		cat ${WORKDIR}/additem_${NUM}.json.template | sed -e "s/EXT_CODE/${i}/g" \
		    -e "s/VARIANT_UUID_${NUM}/${VARIANT_UUID}/g" \
		    -e "s/VARIANT_NAME_${NUM}/${VARIANT_NAME}/g" \
		    -e "s/VARIANT_VAL_${NUM}/${VARIANT_VAL}/g" \
		    -e "s/NEW_UUID_${NUM}/${NEW_UUID}/g" \
                    -e "s/PRODUCT_FOLDER_${NUM}/${PRODUCT_FOLDER}/g" >> /tmp/${FILE_PART}_${i}_test.json
	#sleep 2

	NUM=$(( $NUM + 1 ))

	done

	# Add img links
	IMG=(`$MYSQL_CMD "SELECT filename FROM items_images WHERE no = '${i}';"`)
        NUM=0
        while [ "${NUM}" -lt "10" ]; do
	    IMAGE=$(echo ${IMG[${NUM}]})
	    cat ${WORKDIR}/addimg_${NUM}.json.template | sed -e "s/IMG_${NUM}/${IMAGE_URL}${IMAGE}/g"  >> /tmp/${FILE_PART}_${i}_image_${NUM}
	    cat /tmp/${FILE_PART}_${i}_image_${NUM} >> /tmp/${FILE_PART}_${i}_test.json
	    rm /tmp/${FILE_PART}_${i}_image_${NUM}

	NUM=$(( $NUM + 1 ))
	done

	# END Making json
	cat ${WORKDIR}/additem_END.json.template | sed -e "s/PRODUCT_NAME/${PRODUCT_NAME}/g" -e "s/MIN_PRICE/${MIN_PRICE}/g" -e "s/ROZNICA_PRICE/${ROZNICA_PRICE}/g" -e "s/BUY_PRICE/${BUY_PRICE_ITOG}/g" -e "s/CODE/${i}/g" \
		-e "s/PRODUCT_FOLDER/${PRODUCT_FOLDER}/g" \
		 >> /tmp/${FILE_PART}_${i}_test.json


	curl -s -X POST  "https://api.moysklad.ru/api/remap/1.2/entity/variant" \
	    -H "Accept-Encoding: gzip" \
	    -H "Authorization: Bearer ${MY_SKLAD_TOKEN}" \
	    -H "Content-Type: application/json" \
	    -o output.gzip \
	    -d "@/tmp/${FILE_PART}_${i}_test.json"

	sleep 10
#	cat output.gzip #| gunzip -c

#rm /tmp/${FILE_PART}_${i}
#rm /tmp/${FILE_PART}_${i}_test.json
done

