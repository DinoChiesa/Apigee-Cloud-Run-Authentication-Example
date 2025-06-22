# Connect into a Cloud Run Service from an Apigee Proxy

This sample demonstrates various ways to connect into a Cloud Run Service from
an Apigee Proxy. In all cases the Cloud Run service requires Authentication,
which means the caller, in this case Apigee, must pass an Authorization header
containing an Identity Token.

The proxy uses these approaches:

- passthrough - the call into Apigee must pass an Authorization header
  containing an ID Token; Apigee then relays that header to the upstream Cloud
  Run service.

- platform authentication - the call into Apigee does not
  carry authentication. The Apigee proxy uses Apigee to automatically obtain an
  Identity token for use with the upstream Cloud Run service.

- "impersonation" authentication - the proxy calls into the IAM credentials endpoint to
  "manually" obtain an Identity token for use with the upstream Cloud Run
  service.

- "indirect" authentication - the proxy calls into Secret Manager to retrieve a
  key file for a 2nd service account, and then uses _that key_ to obtain an
  Identity token for use with the upstream Cloud Run service.


None of these options use [IAP](https://cloud.google.com/security/products/iap?e=48754805&hl=en) in front of
the Cloud Run service. The IAP is normally used to front services that will be accessed directly by
human users. It's not useful for services that will be invoked only by other services.

## Disclaimer

This sample is not an official Google product, nor is it part of an
official Google product.

## License

This sample is [Copyright © 2025 Google LLC](./NOTICE).
and is licensed under the [Apache 2.0 License](LICENSE). This includes the bash scripts, the nodejs code,
as well as the API Proxy configuration.

## Using the Sample

### Prerequisites

You need these things:

  * bash
  * the [gcloud cli](https://cloud.google.com/sdk/docs/install)
  * unzip, curl, jq, sed, mktemp

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

1. edit the env.sh file and provide your settings.

   You can set different projects for the Apigee API Proxy, and the Cloud Run service.

   In the below, I sometimes refer to the project that contains the Cloud Run service
   as "the remote project" - remote w.r.t Apigee.

   Then, source the modified file:
   ```sh
   source ./env.sh
   ```

2. deploy the Cloud Run service.

   This service runs as the default service account in the project.
   ```sh
   ./1-deploy-cloud-run-service.sh
   ```

3. create a service account in the Apigee project
   ```sh
   ./2-create-service-account-in-apigee-local-project.sh
   ```

3. create a service account in the Cloud Run (possibly "remote" w.r.t. Apigee) project
   ```sh
   ./3-create-service-account-in-cloudrun-remote-project.sh
   ```

4. Create and download the service account key file for the service account in the Cloud Run project.

   This is necessary to use the "indirect" approach.
   ```sh
   ./4-create-and-download-service-account-keyfile.sh
   ```

5. Upload that service account key file to Secret Manager in the Apigee project.

   This is also necessary to use the "indirect" approach.
   ```sh
   ./5-upload-service-account-key-to-secret-manager.sh
   ```

5. Grant permission to invoke the cloud run service, to the two service accounts, and to your self,
   if you like:
   ```sh
   ./6-grant_access-to-cloud-run-service-to-sa.sh ${SA_FOR_APIGEE_PROXY} ${APIGEE_PROJECT_ID}
   ./6-grant_access-to-cloud-run-service-to-sa.sh ${SA_IN_CLOUDRUN_PROJECT} ${CLOUDRUN_PROJECT_ID}
   ./6-grant_access-to-cloud-run-service-to-sa.sh "self"
   ```

   You will need to grant yourself access if you want to test the "passthrough" approach.

5. install apigeecli
   ```sh
   ./7-install-apigeecli.sh
   ```

5. Update the Apigee proxy properties file with the URL for the Cloud Run
   Service, and the metadata (name and version) for the Secret.

   ```sh
   ./8-update-proxy-with-cloud-run-url.sh
   ```

5. Import and deploy the API proxy.
   ```sh
   ./9-import-and-deploy-apigee-proxy.sh
   ```

## Invoking the API proxy

1. Use passthrough authentication.

   Here, you obtain your own ID Token, and send it into the Apigee API proxy.
   The proxy relays that token to the upstream Cloud Run service. If you
   have `run.invoker` role on the Cloud Run service, you will see a happy message.

   ```sh
   IDTOKEN=$(gcloud auth print-identity-token)
   curl -i -X GET -H "Authorization: Bearer $IDTOKEN"  -H "auth-type: passthrough" \
       https://${APIGEE_HOST}/v1/samples/cloudrun-authenticated-sample/status
   ```

   In the output, you should a json payload. The email of the caller should be _your email_.

2. Use Platform authentication.

   In this case, Apigee obtains an ID Token, on behalf of its Service Account
   identity via the [Google
   Authentication](https://cloud.google.com/apigee/docs/api-platform/security/google-auth/overview)
   feature in Apigee. Apigee sends that ID Token to the upstream Cloud Run
   service. The Service account you created above should have `run.invoker` role
   on the Cloud Run service, so you will see a happy message.

   ```sh
   curl -i -X GET -H "auth-type: platform" https://${APIGEE_HOST}/v1/samples/cloudrun-authenticated-sample/status
   ```

   In the output, the json payload will show the email address and subject ID
   of the Apigee service account.

3. Use "Impersonation"

   In this case, the Apigee proxy is configured to manually request an ID Token,
   on behalf of a configured Service Account identity, from the Google Cloud IAM
   endpoint. The SA that the  Apigee proxy is running as, must have `iam.serviceAccountTokenCreator`
   role on the Service Account that it requests an Identity Token for.  (This is true even
   if the Service Account requested is the same identity as the caller!, ie if
   a Service Account is requesting an Identity Token for itself.)

   This works like the previous case, and uses the same service account, but
   your API Proxy logic is obtaining the ID token "manually" with a network
   call, and in this case, does not cache it (though you could add to the proxy
   logic, to do so).

   The "impersonated" Service account must have `run.invoker` role on the Cloud
   Run service, in order for this to work. In that case, you will see a happy
   message.

   ```sh
   curl -i -X GET -H "auth-type: impersonated" https://${APIGEE_HOST}/v1/samples/cloudrun-authenticated-sample/status
   ```

   In the output, the json payload will show the email and subject ID of the
   impersonated service account, which should be the same as the email shown in
   the previous variant!

1. Use "Indirect" authentication.

   In this case, the Apigee proxy, running with the identity of a service
   account, retrieves credentials for a _separate_ service account, from the
   Secret Manager. The proxy then uses the private key retrieved from Secret
   Manager to construct an assertion and sends that assertion in a request to
   the oauth2.googleapis.com, to manually request an ID Token, on behalf of the
   2nd Service Account identity, the identity corresponding to the retrieved
   credentials. Apigee sends that ID Token to the upstream Cloud Run service.

   If the 2nd Service account has `run.invoker` role on the Cloud Run service,
   the request will succeed, and you will see a happy message.

   ```sh
   curl -i -X GET -H "auth-type: indirect" https://${APIGEE_HOST}/v1/samples/cloudrun-authenticated-sample/status
   ```

   In the output, the json payload should show the email and subject ID of the
   second (possibly remote) service account.

## Cleanup

Run the cleanup script to remove all the assets:
```sh
./0-clean-up-everything.sh
```

## Support

This is open-source software, and is not a supported part of Apigee. If
you need assistance, you can try inquiring on [the Google Cloud Community forum
dedicated to Apigee](https://goo.gle/apigee-community) There is no service-level
guarantee for responses to inquiries posted to that site.
