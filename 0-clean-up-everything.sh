#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

delete_apiproxy() {
  local proxy_name project outfile num_deploys envname rev
  proxy_name=$1
  project=$2
  printf "\nChecking the API Proxy %s\n" "${proxy_name}"
  if apigeecli apis get --name "$proxy_name" --org "$project" --token "$TOKEN" --disable-check >/dev/null 2>&1; then
    outfile=$(mktemp /tmp/apigee-samples.apigeecli.out.XXXXXX)
    if apigeecli apis listdeploy --name "$proxy_name" --org "$project" --token "$TOKEN" --disable-check >"$outfile" 2>&1; then
      num_deploys=$(jq -r '.deployments | length' "$outfile")
      if [[ $num_deploys -ne 0 ]]; then
        printf "Undeploying %s\n" "${proxy_name}"
        for ((i = 0; i < num_deploys; i++)); do
          envname=$(jq -r ".deployments[$i].environment" "$outfile")
          rev=$(jq -r ".deployments[$i].revision" "$outfile")
          apigeecli apis undeploy --name "${proxy_name}" --env "$envname" --rev "$rev" --org "$project" --token "$TOKEN" --disable-check
        done
      else
        printf "  There are no deployments of %s to remove.\n" "${proxy_name}"
      fi
    fi
    [[ -f "$outfile" ]] && rm "$outfile"

    printf "Deleting the API proxy %s\n" "${proxy_name}"
    apigeecli apis delete --name "${proxy_name}" --org "$project" --token "$TOKEN" --disable-check

  else
    printf "  The proxy %s does not exist.\n" "${proxy_name}"
  fi
}

# ====================================================================
check_shell_variables
APIGEE_PROJECT_ID \
  APIGEE_ENV \
  SA_FOR_APIGEE_PROXY \
  APIGEE_HOST \
  SECRET_NAME \
  CLOUDRUN_PROJECT_ID \
  CLOUDRUN_SERVICE_NAME \
  CLOUDRUN_SERVICE_REGION \
  SA_IN_CLOUDRUN_PROJECT

check_required_commands gcloud jq sed

printf "\nThis script cleans up everything related to the Cloud Run Authenticated access sample.\n"
printf "It will remove and delete:\n"
printf "  - the API Proxy\n"
printf "  - the Service Account in the Apigee project\n"
printf "  - the Service Account in the Cloud Run project\n"
printf "  - the Secret in the Apigee project\n"
printf "  - the Cloud Run service\n"
printf "  - any downloaded service account key file\n"

if ! [[ -d "$HOME/.apigeecli/bin" ]]; then
  printf "\nCannot find apigeecli in the expected place.  You may need to install it.\n"
  exit 1
fi

apigeecli="$HOME/.apigeecli/bin/apigeecli"
TOKEN=$(gcloud auth print-access-token)
proxy_name="cloudrun-authenticated-sample"

# AI! Prompt the user here to make sure they want to continue.

key_file=service-account-key.json

if [[ -f "$key_file" ]]; then
  printf "\nDeleting the key file (%s)....\n" "$key_file"
  rm -f "$key_file"
fi

delete_apiproxy "${proxy_name}" "${APIGEE_PROJECT_ID}"

if gcloud run services describe "${CLOUDRUN_SERVICE_NAME}" \
  --region "$CLOUDRUN_SERVICE_REGION" \
  --project "${CLOUDRUN_PROJECT_ID}" 2>/dev/null; then
  printf "\nDeleting the Cloud Run service....\n"
  gcloud run services delete "${CLOUDRUN_SERVICE_NAME}" \
    --region "$CLOUDRUN_SERVICE_REGION" \
    --project "${CLOUDRUN_PROJECT_ID}" --quiet
else
  printf "\nthe Cloud Run service does not exist....\n"

fi

if gcloud secrets describe "$SECRET_NAME" --project="$APIGEE_PROJECT_ID" --quiet >/dev/null 2>&1; then
  printf "\nDeleting secret (%s)...\n" "${SECRET_NAME}"
  gcloud secrets delete "$SECRET_NAME" --project="$APIGEE_PROJECT_ID" --quiet
else
  printf "\nThe secret (%s) does not exist.\n" "${SECRET_NAME}"
fi

sa_email="${SA_IN_CLOUDRUN_PROJECT}@${CLOUDRUN_PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe "$sa_email" --quiet >/dev/null 2>&1; then
  printf "\nDeleting the service account in the Cloud Run project (%s) ....\n" "$sa_email"
  gcloud iam service-accounts delete "$sa_email"
fi

sa_email="${SA_FOR_APIGEE_PROXY}@${APIGEE_PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe "$sa_email" --quiet >/dev/null 2>&1; then
  printf "\nDeleting the service account in the Apigee project (%s) ....\n" "$sa_email"
  gcloud iam service-accounts delete "$sa_email"
fi
