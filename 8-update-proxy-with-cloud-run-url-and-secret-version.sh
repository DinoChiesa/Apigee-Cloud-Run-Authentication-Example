#!/bin/bash
# -*- mode:shell-script; coding:utf-8; -*-

source ./lib/utils.sh

check_shell_variables CLOUDRUN_PROJECT_ID CLOUDRUN_SERVICE_NAME CLOUDRUN_SERVICE_REGION SECRET_NAME APIGEE_PROJECT_ID SA_FOR_APIGEE_PROXY
check_required_commands gcloud sed mktemp

printf "\nThis script updates the API Proxy properties file to specify the  Cloud Run service URL.\n"
printf "The service will not allow unauthenticated access, so callers will need to supply\n"
printf "an Authorization header with an Identity token.\n"

crun_url=$(gcloud run services describe ${CLOUDRUN_SERVICE_NAME} \
  --project "${CLOUDRUN_PROJECT_ID}" \
  --region "$CLOUDRUN_SERVICE_REGION" \
  --format "value(status.url)")

if [[ -z "$crun_url" ]]; then
  printf "Cannot retrieve the Cloud Run service url; cannot update the properties file.\n"
  exit 1
fi
printf "URL for the Cloud Run service: %s\n" "$crun_url"

secret_urn=$(gcloud secrets versions describe latest --secret "$SECRET_NAME" \
                    --project "$APIGEE_PROJECT_ID" --format='value(name)')
secret_version="${secret_urn##*/}"
sa_email="${SA_FOR_APIGEE_PROXY}@${APIGEE_PROJECT_ID}.iam.gserviceaccount.com"

TMP=$(mktemp /tmp/apigee-setup.tmp.out.XXXXXX)
PROPERTIES_FILE="./apiproxy/resources/properties/settings.properties"
sed -E "s@cloudrun_service_url = .+@cloudrun_service_url = ${crun_url}@g" $PROPERTIES_FILE >$TMP && cp $TMP $PROPERTIES_FILE
sed -E "s@secretid_sakeyjson = .+@secretid_sakeyjson = ${SECRET_NAME}@g" $PROPERTIES_FILE >$TMP && cp $TMP $PROPERTIES_FILE
sed -E "s@secretversion_sakeyjson = .+@secretversion_sakeyjson = ${secret_version}@g" $PROPERTIES_FILE >$TMP && cp $TMP $PROPERTIES_FILE
sed -E "s/sa_to_impersonate = .+/sa_to_impersonate = ${sa_email}/g" $PROPERTIES_FILE >$TMP && cp $TMP $PROPERTIES_FILE
rm -f $TMP
printf "\nThe updated properties file contents:\n"
cat $PROPERTIES_FILE

printf "\nOK.\n\n"
