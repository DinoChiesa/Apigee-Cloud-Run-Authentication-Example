#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables APIGEE_PROJECT_ID SA_FOR_APIGEE_PROXY SECRET_NAME

key_file=service-account-key.json

printf "\nThis script uploads a service account key file into Google Cloud Secret Manager.\n"
printf "project: %s\n" "$APIGEE_PROJECT_ID"
printf "SA key file: %s\n" "$key_file"
printf "Secret name: %s\n" "$SECRET_NAME"

if ! [[ -f "$key_file" ]]; then
  printf "\nThe key file '%s' does not exist.\n" "$key_file"
  printf "Aborting.\n"
  exit 1
fi

if ! gcloud secrets create "$SECRET_NAME" --data-file="$key_file" \
  --project "$APIGEE_PROJECT_ID" 2>/dev/null; then
  printf "\nDid not succeed creating the secret.\n"
  printf "Aborting.\n"
  exit 1
fi

printf "\nSucceeded creating the secret.\n"
printf "\nGranting permissions...\n"

REQUIRED_ROLE="roles/secretmanager.secretAccessor"
sa_email="${SA_FOR_APIGEE_PROXY}@${APIGEE_PROJECT_ID}.iam.gserviceaccount.com"

gcloud secrets add-iam-policy-binding "projects/${APIGEE_PROJECT_ID}/secrets/${SECRET_NAME}" \
  --member "serviceAccount:${sa_email}" \
  --role "${REQUIRED_ROLE}"

printf "\nOk.\n\n"
