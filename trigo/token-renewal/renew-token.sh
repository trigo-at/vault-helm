#!/bin/bash

set -x
set -e

OC_COMMAND="/app/oc-bin"
 #gets old token from secret in cluster
TOKEN=$(${OC_COMMAND} get secret  vault-unsealer -n vault -o go-template  --template="{{.data.VAULT_TOKEN}}" | base64 -d - )

 #creates new token from secondary vault in VM (orphan token is used as it will not expire when parent token expires)
RESPONSE=$(curl --header "X-Vault-Token: ${TOKEN}" --request POST -d '"policies": ["autounseal", "autorenew"]' https://vault-backup.ocp.trigo.cloud:8200/v1/auth/token/create-orphan)
NEWTOKEN=$( echo $RESPONSE | jq .auth.client_token)

${OC_COMMAND} process -n vault -p NEWTOKEN=${NEWTOKEN} -f /app/vault-unsealer.yaml | ${OC_COMMAND}  apply -n vault -f -