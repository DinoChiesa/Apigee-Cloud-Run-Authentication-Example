#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_NAME CLOUDRUN_SERVICE_REGION

printf "\nThis script grants invoker rights to the Cloud Run service named '%s'\n" "$CLOUDRUN_SERVICE_NAME"
printf "in the project '%s'.\n" "$CLOUDRUN_PROJECT_ID"

if [[ -z "$1" ]]; then
  printf "No input provided, will attempt to grant permission to the current user.\n"
  GWHOAMI=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
  if [[ -z "$GWHOAMI" ]]; then
    printf "Not authenticated to Google Cloud, cannot continue.\n"
    exit 1
  fi
  printf "Current user: %s\n" "${GWHOAMI}"
  PRINCIPAL="user::${GWHOAMI}"
else
  SA_EMAIL="$1"
  if ! [[ "$SA_EMAIL" == *"@"* ]]; then
    printf "You need to provide a full Service Account email as the argument.\n"
    exit 1
  fi
  printf "Checking existence of Service Account '%s'\n" "$SA_EMAIL"
  if ! gcloud iam service-accounts describe "$SA_EMAIL" --quiet >> /dev/null; then
    printf "Cannot validate that Service Account in Google Cloud, cannot continue.\n"
    exit 1
  fi
  PRINCIPAL="serviceAccount:${SA_EMAIL}"
fi

gcloud run services add-iam-policy-binding "$CLOUDRUN_SERVICE_NAME" \
          --project "${CLOUDRUN_PROJECT_ID}" \
          --region "$CLOUDRUN_SERVICE_REGION" \
          --member "$PRINCIPAL" \
          --role "roles/run.invoker" \


