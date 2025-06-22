#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables SA_FOR_APIGEE_PROXY APIGEE_PROJECT_ID CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_REGION CLOUDRUN_SERVICE_NAME
check_required_commands gcloud jq

printf "\nThis script checks and maybe creates a Service Account for use by the Apigee API Proxy.\n"
printf "Service account name: %s\n" "${SA_FOR_APIGEE_PROXY}"
printf "Service Account project: %s\n\n" "${APIGEE_PROJECT_ID}"

create_sa_and_apply_permissions "${SA_FOR_APIGEE_PROXY}" "${APIGEE_PROJECT_ID}"

printf "\nGranting roles/iam.serviceAccountTokenCreator on that Service Account...\n"

sa_email="${SA_FOR_APIGEE_PROXY}@${APIGEE_PROJECT_ID}.iam.gserviceaccount.com"
gcloud iam service-accounts add-iam-policy-binding "${sa_email}" \
       --project "${APIGEE_PROJECT_ID}" \
       --member "serviceAccount:${sa_email}" \
       --role "roles/iam.serviceAccountTokenCreator"

printf "\nOk.\n\n"
