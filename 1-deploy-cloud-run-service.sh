#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_NAME CLOUDRUN_SERVICE_REGION
check_required_commands gcloud

printf "\nThis script deploys or redeploys the Cloud Run service named '%s'\n" "$CLOUDRUN_SERVICE_NAME"
printf "in the project '%s'.\n" "$CLOUDRUN_PROJECT_ID"
printf "The script uses the Cloud Run \"deploy from source\" approach in the nodejs app directory.\n"
printf "The service will not allow unauthenticated access, so callers will need to supply\n"
printf "an Authorization header with an Identity token.\n"

cd app
gcloud run deploy ${CLOUDRUN_SERVICE_NAME} \
  --source . \
  --concurrency 5 \
  --cpu 1 \
  --memory '512Mi' \
  --min-instances 0 \
  --max-instances 1 \
  --no-allow-unauthenticated \
  --region "$CLOUDRUN_SERVICE_REGION" \
  --project "${CLOUDRUN_PROJECT_ID}"

