#!/bin/bash

help()
{
   echo "Datadog Cloud Workload Security plugin"
   echo
   echo "Syntax: dd-cws update-policy [--api-key|--app-key|--site"
   echo
   echo "options:"
   echo "--api-key     Specify the API Key."
   echo "--app-key     Specify the Application Key."
   echo "--site        Specify the site."
   echo
}

API_KEY=${API_KEY:-}
APP_KEY=${APP_KEY:-}
SITE=${SITE:-}

ARGUMENTS=(
  "help"
  "api-key"
  "app-key"
  "site"
)

opts=$(getopt \
  --longoptions "$(printf "%s:," "${ARGUMENTS[@]}")" \
  --name "$(basename "$0")" \
  --options "" \
  -- "$@"
)

eval set --$opts

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      help
      exit
      ;;

    --api-key)
      API_KEY=$2
      shift 2
      ;;

    --app-key)
      APP_KEY=$2
      shift 2
      ;;

    --site)
      SITE=$2
      shift 2
      ;;

    *)
      break
      ;;
  esac
done


if [ -z "${API_KEY}" ]; then
	>&2 printf "An API Key is required \U1F4A5\n"
	exit
fi

if [ -z "${APP_KEY}" ]; then
	>&2 printf "An APP Key is required \U1F4A5\n"
	exit
fi

TEMP_POLICIES_DIR=$(mktemp -d /tmp/cws-XXXX)

curl -s -q -o ${TEMP_POLICIES_DIR}/default.policy https://api.${SITE}/api/v2/security/cloud_workload/policy/download -H "DD-API-KEY: ${API_KEY}" -H "DD-APPLICATION-KEY: ${APP_KEY}"

kubectl get configmap runtime-security-policies 1>/dev/null 2>/dev/null
if [ $? -ne 0 ]
then
	kubectl create configmap runtime-security-policies --from-file=${TEMP_POLICIES_DIR}
	helm upgrade datadog-agent --set datadog.securityAgent.runtime.policies.configMap="runtime-security-policies" --reuse-values datadog/datadog
else
	kubectl delete configmap runtime-security-policies >/dev/null
	kubectl create configmap runtime-security-policies --from-file=${TEMP_POLICIES_DIR} >/dev/null
fi

printf "Updated \U1F37E\n"
