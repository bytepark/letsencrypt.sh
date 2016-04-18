#!/usr/bin/env bash

#
# Example how to deploy a DNS challenge using nsupdate
#

set -e
set -u
set -o pipefail
umask 077

source ./private

DOMAIN="${2}"
STRIPPED_DOMAIN=`echo $DOMAIN | sed -e "s/www\.//"`

updatefile="$(mktemp)"

# function get_content {
#     curl 
# }

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
                 "name": "${2}",
                 "type": "TXT",
                 "content": "${4}",
                 "ttl": 300
             }
         ]
     }
EOT

    curl -H "Content-Type: application/json" -X POST -d @"${updatefile}" https://partner.http.net/api/dns/v1/json/zoneUpdate
    #printf "update add _acme-challenge.%s. 300 in TXT \"%s\"\n\n" "${2}" "${4}" > asd
    #$NSUPDATE "${updatefile}"
    done="yes"
fi

if [[ "$1" = "clean_challenge" ]]; then
    printf "update delete _acme-challenge.%s. 300 in TXT \"%s\"\n\n" "${2}" "${4}" > "${updatefile}"
    $NSUPDATE "${updatefile}"
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