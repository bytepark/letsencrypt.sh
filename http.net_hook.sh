#!/usr/bin/env bash

set -e
set -u
set -o pipefail
umask 077

source ./private

DOMAIN="${2}"
STRIPPED_DOMAIN=`echo $DOMAIN | awk -F. '{if ($(NF-1) == "co") printf $(NF-2)"."; printf $(NF-1)"."$(NF)"\n";}' `

updatefile="$(mktemp)"

done="no"

if [[ "$1" = "deploy_challenge" ]]; then
cat <<EOT > ${updatefile}
     {
         "authToken": "$API_KEY",
         "zoneConfig": {
             "name": "$STRIPPED_DOMAIN"
         },
         "recordsToAdd": [
             {
                 "name": "_acme-challenge.${2}",
                 "type": "TXT",
                 "content": "${4}",
                 "ttl": 300
             }
         ]
     }
EOT
    # debug
    #cat ${updatefile}
    # production
    curl -H "Content-Type: application/json" -X POST -d @"${updatefile}" https://partner.http.net/api/dns/v1/json/zoneUpdate

    done="yes"
fi

if [[ "$1" = "clean_challenge" ]]; then
cat <<EOT > ${updatefile}
     {
         "authToken": "$API_KEY",
         "zoneConfig": {
             "name": "$STRIPPED_DOMAIN"
         },
         "recordsToDelete": [
             {
                 "name": "_acme-challenge.${2}",
                 "type": "TXT",
                 "content": "${4}",
             }
         ]
     }
EOT
    # debug
    #cat ${updatefile}
    # production
    curl -H "Content-Type: application/json" -X POST -d @"${updatefile}" https://partner.http.net/api/dns/v1/json/zoneUpdate

    done="yes"
fi

if [[ "${1}" = "deploy_cert" ]]; then
    # do nothing for now
    done="yes"
fi

rm -f "${updatefile}"

if [[ ! "${done}" = "yes" ]]; then
    echo Unkown hook "${1}"
    exit 1
fi

exit 0