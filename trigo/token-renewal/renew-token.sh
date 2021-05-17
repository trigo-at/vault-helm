#!/bin/bash

set -x

OC_COMMAND="/app/oc-bin"
SLACK_WEBHOOK_URL=$(${OC_COMMAND} get secret vault-backup-cron-job -n vault -o go-template  --template="{{.data.SLACK_WEBHOOK_URL}}" | base64 -d - )
RENEW_URL="https://vault-backup.ocp.trigo.cloud:8200/v1/auth/token/renew-self"


trap "exit 1" TERM
export TOP_PID=$$

_die() {
    kill -s TERM $TOP_PID
}

send_slack() {
	echo $1
	status="good"
	message="SUCCESS! ... "
	if [[ $1 -eq 1 ]]; then
		status="danger"; 
		message="🐞🐞🐞 ";
	fi

	message="${message}$2"
	
msg=$(cat <<JSON
{ 
"color":"#ff0000",
"mrkdwn": true,
"attachments": [{
	"fallback": "ERROR",
	"color": "${status}",
	"text": "${message}",
	"mrkdwn_in": ["fields"]
}]}
JSON
)
	echo $msg
	curl -X POST \
		--data-urlencode "payload=${msg}" \
		${SLACK_WEBHOOK_URL};
}
TOKEN=$(${OC_COMMAND} get secret  vault-unsealer -n vault -o go-template  --template="{{.data.VAULT_TOKEN}}" | base64 -d - )

curl --fail --request POST --header "X-Vault-Token: ${TOKEN}" ${RENEW_URL}; echo $? > /tmp/error;
ERRORFILE=$(cat /tmp/error)

checkResponse() {
	if [ "${ERRORFILE}" != "0" ]; then
		send_slack 1 "*ERROR: renewing vault unseal token with Curl ErrorCode: ${ERRORFILE}"
		_die
	else
		send_slack 0 "Succesfully renewed periodic lease for auto unseal token"
	fi
}

checkResponse