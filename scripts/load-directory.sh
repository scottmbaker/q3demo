#!/bin/sh

API_BASE_URL=$1
DIRECTORY=$2

cd $DIRECTORY
for file in $(ls *.json)
do
    base=${file%.json}
    target=${base#*-}
    target=${target%%#*}
    echo Post: ${DIRECTORY}/${file}
    echo ${target}
    aether-post-internal ${target} ${file}
#    curl --location --request POST ${API_BASE_URL}/${target} \
#        --header 'Content-Type: application/json' \
#        --data @${file}
    echo ""
done
