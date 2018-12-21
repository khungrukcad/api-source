#!/bin/sh
VERSION="v1"
MIN_BUILD="1281"
PROVIDERS="PIA"
WEB="../api/$VERSION"

cd `dirname $0`

for P_NAME in $PROVIDERS; do
    P_KEY=`echo $P_NAME | tr '[:upper:]' '[:lower:]'`
    JSON="$P_KEY.json"
    ENDPOINT="net"
    
    echo ""
    echo "====== $P_NAME ======"
    echo ""

    echo "Deleting old JSON..."
    rm -f "$WEB/$ENDPOINT/$JSON"
    echo "Scraping..."

    # inject "build" (MIN_BUILD) and "name" (P_NAME) into net JSON
    sh providers/$P_KEY/$ENDPOINT.sh | ruby inject.rb $MIN_BUILD $P_NAME >"$WEB/$ENDPOINT/$JSON"
done
