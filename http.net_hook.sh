#!/bin/bash

#set -e
#set -u
#set -o pipefail
umask 077

source ./private

DOMAIN="${2}"
TOKEN="${4}"
STRIPPED_DOMAIN=`echo $DOMAIN | awk -F. '{if ($(NF-1) == "co") printf $(NF-2)"."; printf $(NF-1)"."$(NF)"\n";}' `
#OLD_TOKEN=`dig +trace +short -t TXT _acme-challenge.${2} | grep -Eo '["].*["]' | sed -e 's/"//g' `
updatefile="$(mktemp)"

strip_domain() {
    COUNT=`echo "$1" |  grep -o "\." | wc -l`
    #awk -F. '{if ($(NF-1) == "co") printf $(NF-2)"."; printf $(NF-2)"\n";}'
}

done="no"

if [[ "$1" = "deploy_challenge" ]]; then
    echo "ddd"
OLD_TOKEN=$(dig +trace +short -t TXT _acme-challenge.${2} |
             grep -Po '".*?"' |
             sed -e 's/"//g' )
            
echo "$OLD_TOKEN"
echo "asd"
    # if there is already a certificate/dns entry, update the entry
    if [[ "$OLD_TOKEN" ]]; then
        echo "debug:token exists"
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
         ],
         "recordsToDelete": [
             {
                 "name": "_acme-challenge.das.byte-park.org",
                 "type": "TXT",
                 "content": "$OLD_TOKEN"
             }
         ]
     }
EOT
cat "${updatefile}"

    else
        echo "debug: token empty"
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
cat "${updatefile}"
    fi

    echo "debug:curl"
    curl -H "Content-Type: application/json" -X POST -d @"${updatefile}" https://partner.http.net/api/dns/v1/json/zoneUpdate #&> /dev/null

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
                     "content": "${4}"
                 }
         ]
}
EOT

    curl -H "Content-Type: application/json" -X POST -d @"${updatefile}" https://partner.http.net/api/dns/v1/json/zoneUpdate &> /dev/null
    echo "doing clean"
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