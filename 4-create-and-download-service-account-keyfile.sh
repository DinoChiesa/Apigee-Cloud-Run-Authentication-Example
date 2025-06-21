#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_NAME CLOUDRUN_SERVICE_REGION SA_IN_CLOUDRUN_PROJECT

printf "\nThis script grants invoker rights to the Cloud Run service named '%s'\n" "$CLOUDRUN_SERVICE_NAME"
printf "in the project '%s'.\n" "$CLOUDRUN_PROJECT_ID"

sa_email="${SA_IN_CLOUDRUN_PROJECT}@${CLOUDRUN_PROJECT_ID}.iam.gserviceaccount.com"
key_file=service-account-key.json

# AI! Here, check the existence of the file noted in $key_file, and if it exists,
# print an message to the user, and confirm that the user wants to continue
# creating a new key file. 

rm -f "$key_file"
if ! gcloud iam service-accounts keys create "$key_file" --iam-account "$sa_email" 2>/dev/null; then
  printf "Cannot create Service Account key file, cannot continue.\n"
  exit 1
fi

if ! [[ -f $key_file ]]; then
  printf "The Service Account key file does not exist, cannot continue.\n"
  exit 1
fi

printf "The Service Account key file has been downloaded.\n"
