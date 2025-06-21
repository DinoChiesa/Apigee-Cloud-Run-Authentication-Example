#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

import_and_deploy_apiproxy() {
  local proxy_name project
  proxy_name=$1
  project=$2
  REV=$(apigeecli apis create bundle -f "./bundles/${proxy_name}/apiproxy" -n "$proxy_name" --org "$PROJECT" --token "$TOKEN" --disable-check | jq ."revision" -r)
  apigeecli apis deploy --wait --name "$proxy_name" --ovr --rev "$REV" --org "$PROJECT" --env "$APIGEE_ENV" --token "$TOKEN" --disable-check
}

# ====================================================================

check_shell_variables APIGEE_PROJECT_ID APIGEE_ENV SA_FOR_APIGEE_PROXY
check_required_commands gcloud jq

SA_EMAIL="${SA_FOR_APIGEE_PROXY}@${APIGEE_PROJECT_ID}.iam.gserviceaccount.com"

printf "\nThis script imports and deploys the Apigee API Proxy for this sample,\n"
printf "into the Apigee project '%s'\n" "$APIGEE_PROJECT_ID"
printf "using the service account '%s'\n" "$SA_EMAIL"

if ! [[ -d "$HOME/.apigeecli/bin" ]]; then
  printf "\nCannot find apigeecli in the expected place.  You may need to install it.\n"
  exit 1
fi

apigeecli="$HOME/.apigeecli/bin"
TOKEN=$(gcloud auth print-access-token)
proxy_name="cloudrun-authenticated-sample"

REV=$($apigeecli apis create bundle -f "./apiproxy" -n "$proxy_name" \
  --org "$APIGEE_PROJECT_ID" --token "$TOKEN" --disable-check | jq ."revision" -r)

$apigeecli apis deploy --wait --name "$proxy_name" \
  --ovr --rev "$REV" \
  --sa "$SA_EMAIL" \
  --org "$APIGEE_PROJECT_ID" \
  --env "$APIGEE_ENV" --token "$TOKEN" --disable-check
