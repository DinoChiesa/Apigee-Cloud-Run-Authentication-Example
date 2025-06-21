#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_NAME CLOUDRUN_SERVICE_REGION

printf "\nThis script grants invoker rights to the Cloud Run service named '%s'\n" "$CLOUDRUN_SERVICE_NAME"
printf "in the project '%s'.\n" "$CLOUDRUN_PROJECT_ID"

if [[ "$1" != "self" ]] && ( [[ -z "$1" ]] || [[ -z "$2" ]] ); then
    printf "\nError: Invalid arguments.\n"
    printf "This script requires either 'self' as an argument, or a service account name and project id.\n"
    printf "Usage: %s self\n" "$0"
    printf "   or: %s <sa_name> <sa_project_id>\n\n" "$0"
    exit 1
fi

if [[ "$1" == "self" ]]; then
  printf "Granting invoke permission to the current gcloud user.\n"
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

