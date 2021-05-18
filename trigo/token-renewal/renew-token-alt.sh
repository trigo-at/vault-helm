#DEPRECATED! keeping it in repo as pieces of code might be useful for other operations in vault!
# new and better version for renewing token in ./renew-token.sh


#!/bin/bash

set -ex
OC_COMMAND="/app/oc-bin"
SLACK_WEBHOOK_URL=$(${OC_COMMAND} get secret vault-backup-cron-job -n vault -o go-template  --template="{{.data.SLACK_WEBHOOK_URL}}" | base64 -d - )

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

test() { 
    if [ ${NEWTOKEN} == "null" ]; then
        send_slack 1 "Failed to renew Vault Unseal Token, RESPONSE is ${RESPONSE}"
        _die
    fi

	# if [ $RESPONSE | jq 'keys[]' == "errors" ]; then
    #     send_slack 1 "Failed to renew Vault Unseal Token, RESPONSE is ${RESPONSE}"
    #     exit 1
    # fi
	#send_slack 0 "New token for vault transit engine autounseal obtained successfully"
}
apply() {
	${OC_COMMAND} process -n vault -p NEWTOKEN=${NEWTOKEN} -f /app/vault-unsealer.yaml | ${OC_COMMAND}  apply -n vault -f -
	#send_slack 0 "New token for vault transit engine autounseal obtained successfully"
}

payload=$(cat <<JSON
{
    "role": "backup",
    "jwt": "${TOKEN}"
	"period": 
}
JSON
)

 #sets TOKEN variable to value of JWT for kubernetes auth method in backup vault
TOKEN=$(${OC_COMMAND} get secret  vault-auth-token-q9jxm -n vault -o go-template  --template="{{.data.token}}" | base64 -d - )
 #obtains token from response to curl command with fitting policies via kubernetes auth method in backup vault
RESPONSE=$(curl --request POST --data ${payload} https://vault-backup.ocp.trigo.cloud:8200/v1/auth/kubernetes/login)
#sets variable to value of new token
NEWTOKEN=$( echo $RESPONSE | jq .auth.client_token)

#makes sure no empty secret is created and modifies secret with new tokenvalue
test
#apply