#!/bin/bash
# Copyright 2024-2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CURL() {
  [[ -z "${CURL_OUT}" ]] && CURL_OUT=$(mktemp /tmp/appint-setup-script.curl.out.XXXXXX)
  [[ -f "${CURL_OUT}" ]] && rm ${CURL_OUT}
  #[[ $verbosity -gt 0 ]] && echo "curl $@"
  [[ $verbosity -gt 0 ]] && echo "curl $@"
  CURL_RC=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $TOKEN" -o "${CURL_OUT}" "$@")
  [[ $verbosity -gt 0 ]] && echo "==> ${CURL_RC}"
}

googleapis_whoami() {
  # for diagnostic purposes only
  CURL -X GET "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"
  if [[ ${CURL_RC} -ne 200 ]]; then
    printf "cannot inquire userinfo"
    cat ${CURL_OUT}
    exit 1
  fi

  printf "\nGoogle access token info:\n"
  cat ${CURL_OUT}
}

check_shell_variables() {
  local MISSING_ENV_VARS
  MISSING_ENV_VARS=()
  for var_name in "$@"; do
    if [[ -z "${!var_name}" ]]; then
      MISSING_ENV_VARS+=("$var_name")
    fi
  done

  [[ ${#MISSING_ENV_VARS[@]} -ne 0 ]] && {
    printf -v joined '%s,' "${MISSING_ENV_VARS[@]}"
    printf "You must set these environment variables: %s\n" "${joined%,}"
    exit 1
  }

  printf "Settings in use:\n"
  for var_name in "$@"; do
    printf "  %s=%s\n" "$var_name" "${!var_name}"
  done
}

check_required_commands() {
  local missing
  missing=()
  for cmd in "$@"; do
    #printf "checking %s\n" "$cmd"
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [[ -n "$missing" ]]; then
    printf -v joined '%s,' "${missing[@]}"
    printf "\n\nThese commands are missing; they must be available on path: %s\nExiting.\n" "${joined%,}"
    exit 1
  fi
}

create_sa_and_apply_permissions() {
  local short_sa project sa_email iam_policy_json has_role
  short_sa="$1"
  project="$2"
  sa_email="${short_sa}@${project}.iam.gserviceaccount.com"

  if gcloud iam service-accounts describe "$sa_email" &>/dev/null; then
    printf "The Service Account '%s' exists.\n" "$sa_email"
    printf "Checking permissions on the Cloud Run service...\n"
    iam_policy_json=$(gcloud run services get-iam-policy "$CLOUDRUN_SERVICE_NAME" \
      --project "$CLOUDRUN_PROJECT_ID" \
      --region="$CLOUDRUN_SERVICE_REGION" \
      --format=json 2>/dev/null)

    has_role=$(echo "$iam_policy_json" |
      jq --arg principal "serviceAccount:$sa_email" \
        '.bindings[] | select(.role == "roles/run.invoker") | .members | any(. == $principal)')
    if [[ "$has_role" == "true" ]]; then
      need_permissions=0
    else
      need_permissions=1
    fi
  else
    printf "Creating the Service Account '%s'...\n" "$sa_email"
    gcloud iam service-accounts create "$short_sa" --project "${project}"
    printf "Sleeping a bit, before granting permissions....\n"
    sleep 12
    need_permissions=1
  fi

  if [[ $need_permissions -eq 1 ]]; then
    gcloud run services add-iam-policy-binding "$CLOUDRUN_SERVICE_NAME" \
      --project "$CLOUDRUN_PROJECT_ID" \
      --region="$CLOUDRUN_SERVICE_REGION" \
      --member "serviceAccount:${sa_email}" \
      --role "roles/run.invoker"
  fi

}
