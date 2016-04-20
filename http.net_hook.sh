#!/bin/bash

#set -e
#set -u
#set -o pipefail
umask 077

source ./private

DOMAIN="${2}"
CHALLENGE_TOKEN="${3}"
TOKEN="${4}"
STRIPPED_DOMAIN=`echo $DOMAIN | awk -F. '{if ($(NF-1) == "co") printf $(NF-2)"."; printf $(NF-1)"."$(NF)"\n";}' `
updatefile="$(mktemp)"
OLD_TOKEN=$(dig +trace +short -t TXT _acme-challenge.${2} |
             grep -Po '".*?"' |
             sed -e 's/"//g' )
done="no"

if [[ "$1" = "deploy_challenge" ]]; then
    printf "deploy_challenge called DOMAIN=$DOMAIN CHALLENGE_TOKEN=$CHALLENGE_TOKEN TOKEN_VALUE_DNS=$TOKEN"

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

    curl -H "Content-Type: application/json" -X POST -d @"${updatefile}" https://partner.http.net/api/dns/v1/json/zoneUpdate &> /dev/null

    # waiting for deploy of the token, so that verify works
    while ! dig +trace +short -t TXT _acme-challenge.$DOMAIN | grep -- "$TOKEN" > /dev/null
        do
           printf "."
           sleep 3
        done

    done="yes"
fi

if [[ "$1" = "clean_challenge" ]]; then

    printf "clean_challenge called with DOMAIN=$DOMAIN CHALLENGE_TOKEN=$CHALLENGE_TOKEN TOKEN_VALUE_DNS=$TOKEN"

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
                     "content": "\"${4}\""
                 }
         ]
}
EOT

    curl -H "Content-Type: application/json" -X POST -d @"${updatefile}" https://partner.http.net/api/dns/v1/json/zoneUpdate &> /dev/null
    done="yes"
fi

if [[ "${1}" = "deploy_cert" ]]; then
    service nginx reload
    done="yes"
fi

if [[ "${1}" = "unchanged_cert" ]]; then
    done="yes"
fi

#rm -f "${updatefile}"

if [[ ! "${done}" = "yes" ]]; then
    echo Unkown hook "${1}"
    exit 1
fi

exit 0