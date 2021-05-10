#!/bin/bash

TOKEN=(oc get secret  vault-backup-cron-job -n vault -o go-template  --template="{{.data.IMPORT_VAULT_TOKEN}}" | base64 -d - ) \
curl \
   -H "X-Vault-Token: ${TOKEN}" \
   -X GET \
   https://vault-backup.ocp.trigo.cloud:8200/v1/auth/token/create \
   policies="autounseal" \
   


oc update secret vault-unsealer -f newtoken.yaml<<<EOF
type: secret
VAULT_TOKEN: ${NEWTOKEN}
EOF>>>

vault write auth/kubernetes/config \
    token_reviewer_jwt="<your reviewer service account JWT>" \
    kubernetes_host=https://api.ocp.trigo.cloud:6443 \
    kubernetes_ca_cert=@ca.crt



works:

curl \
>    --header "X-Vault-Token: s.uXZOBT1AtjRGB1ZONgqnkwlL" \
>    --request POST -d '"policies": ["autounseal"]' \
>    https://vault-backup.ocp.trigo.cloud:8200/v1/auth/token/create 


curl \
    --header "X-Vault-Token: s.uXZOBT1AtjRGB1ZONgqnkwlL" \
    --request POST -d '"policies": ["autounseal"]' \
    https://vault-backup.ocp.trigo.cloud:8200/v1/auth/token/create 

{"request_id":"b7718f9e-bc9d-0d97-ce4e-4f272be21357","lease_id":"","renewable":false,"lease_duration":0,"data":null,"wrap_info":null,"warnings":null,"auth":{"client_token":"s.bv6VHzF5ywh7Y99PxhVUIggM","accessor":"38rEzUhGp9pKcA4be3YWNBeM","policies":["root"],"token_policies":["root"],"metadata":null,"lease_duration":0,"renewable":false,"entity_id":"","token_type":"service","orphan":false}}




TOKEN=(oc get secret  vault-unsealer -n vault -o go-template  --template="{{.data.VAULT_TOKEN}}" | base64 -d - ) \
NEWTOKEN=(curl --header "X-Vault-Token: TOKEN" --request POST -d '"policies": ["autounseal", "autorenew"]' https://vault-backup.ocp.trigo.cloud:8200/v1/auth/token/create-orphan | jq auth.client_token.value)
oc get secret vault-unsealer -o json | jq '.data["VAULT_TOKEN"]="$NEWTOKEN"' | oc apply -f -



