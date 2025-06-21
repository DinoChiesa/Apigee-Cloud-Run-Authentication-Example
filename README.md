# connect into a Cloud Run Service from an Apigee Proxy

This sample demonstrates various ways to connect into a Cloud Run Service from
an Apigee Proxy. In all cases the Cloud Run service requires Authentication.

The proxy uses these approaches:

- passthrough - the caller must pass an Authorization header, which is relayed
  to the upstream Cloud Run service

- platform authentication - the proxy uses Apigee to automatically obtain an
  Identity token for use with the upstream Cloud Run service

- "manual" authentication - the proxy calls into the metadata endpoint to
  "manually" obtain an Identity token for use with the upstream Cloud Run
  service

- "indirect" authentication - the proxy calls into Secret Manager to retrieve a
  key file for a 2nd service account, and then uses _that key_ to obtain an
  Identity token for use with the upstream Cloud Run service.


## Using the Sample

### Prerequisites

You need these things:

    * [gcloud SDK](https://cloud.google.com/sdk/docs/install)
    * unzip
    * curl
    * jq

You can get all of this in [Google Cloud Shell](https://cloud.google.com/shell/docs/launching-cloud-shell).

### On Projects and Permissions

You can have the Cloud Run service running in a different project than your Apigee API proxy.

To make this all work, it's easiest if  you are "Owner" or "Editor" in the various projects.
I haven't determined exactly which permissions you require.

You will need the permission to perform these actions:

- importing and deploying Apigee proxies
- deploying Cloud Run using Cloud Build (import from source)
- creating service accounts
- updating IAM policy on Cloud Run services
- creating and downloading service account keys


## Setup steps

To prepare:

1. edit the env.sh file and provide your settings. Then, source the modified file:
   ```sh
   source ./env.sh
   ```

2. deploy the Cloud Run service.
   ```sh
   1-deploy-cloud-run-service.sh
   ```

Follow the steps to provision

