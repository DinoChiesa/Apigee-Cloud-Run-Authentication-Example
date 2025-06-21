#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_NAME CLOUDRUN_SERVICE_REGION SA_IN_CLOUDRUN_PROJECT

printf "\nThis script creates and downloads a Service Account key\n"
printf "project: %s\n" "$CLOUDRUN_PROJECT_ID"
printf "Service Account: %s\n" "$SA_IN_CLOUDRUN_PROJECT"

sa_email="${SA_IN_CLOUDRUN_PROJECT}@${CLOUDRUN_PROJECT_ID}.iam.gserviceaccount.com"
key_file=service-account-key.json

if [[ -f "$key_file" ]]; then
  printf "\nThe key file '%s' already exists.\n" "$key_file"
  read -p "Do you want to overwrite it and create a new key? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    printf "Aborting.\n"
    exit 1
  fi
fi

rm -f "$key_file"
if ! gcloud iam service-accounts keys create "$key_file" --iam-account "$sa_email" 2>/dev/null; then
  printf "Cannot create Service Account key file, cannot continue.\n"
  exit 1
fi

if ! [[ -f $key_file ]]; then
  printf "The Service Account key file does not exist, cannot continue.\n"
  exit 1
fi

printf "The Service Account key file has been downloaded: %s.\n" "$key_file"
