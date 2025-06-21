#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_NAME CLOUDRUN_SERVICE_REGION

printf "\nThis script grants invoker rights to the Cloud Run service named '%s'\n" "$CLOUDRUN_SERVICE_NAME"
printf "in the project '%s'.\n" "$CLOUDRUN_PROJECT_ID"

# AI! modify the logic here to check for two positional arguments.
# If the first argument takes the special argument "self", then no further check is required. 
# Otherwise, check for othe existence of the first and second,
# and if either is missing or empty, print an appropriate message and exit. 



if [[ "$1" == "self" ]]; then
  printf "No input provided, will attempt to grant permission to the current user.\n"
  GWHOAMI=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
  if [[ -z "$GWHOAMI" ]]; then
    printf "Not authenticated to Google Cloud, cannot continue.\n"
    exit 1
  fi
  printf "Current user: %s\n" "${GWHOAMI}"
  PRINCIPAL="user:${GWHOAMI}"
else
  sa_email="${1}@${2}.iam.gserviceaccount.com"
  printf "Checking existence of Service Account '%s'\n" "$sa_email"
  if ! gcloud iam service-accounts describe "$sa_email" --quiet >> /dev/null; then
    printf "Cannot validate that Service Account in Google Cloud, cannot continue.\n"
    exit 1
  fi
  PRINCIPAL="serviceAccount:${sa_email}"
fi

gcloud run services add-iam-policy-binding "$CLOUDRUN_SERVICE_NAME" \
          --project "${CLOUDRUN_PROJECT_ID}" \
          --region "$CLOUDRUN_SERVICE_REGION" \
          --member "$PRINCIPAL" \
          --role "roles/run.invoker" \


