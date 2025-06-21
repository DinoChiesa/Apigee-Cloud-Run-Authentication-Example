#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables APIGEE_PROJECT_ID

key_file=service-account-key.json
secret_name=sample-sakey-json

printf "\nThis script uploads a service account key file into Google Cloud Secret Manager.\n"
printf "project: %s\n" "$APIGEE_PROJECT_ID"
printf "SA key file: %s\n" "$key_file"

if ! [[ -f "$key_file" ]]; then
  printf "\nThe key file '%s' does not exist.\n" "$key_file"
  printf "Aborting.\n"
  exit 1
fi

if ! gcloud secrets create "$secret_name" --data-file="$key_file" \
  --project "$APIGEE_PROJECT_ID" 2>/dev/null; then
  printf "\nDid not succeed creating the secret.\n"
  printf "Aborting.\n"
  exit 1
fi

printf "\nSucceeded creating the secret.\n"
