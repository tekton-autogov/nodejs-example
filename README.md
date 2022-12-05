# Automated Governance Example with Tekton and NodeJS


## Prerequisites
- An OpenShift cluster
- The `oc` cli
- The `tkn` cli (Optional)
- The cosign cli (Optional. Requred if you want to run the sigstore pipeline). See the [installation docs](https://docs.sigstore.dev/cosign/installation/).

## Installation
1. Install the OpenShift Pipelines operator
3. `oc new-project pipelines`
4. **Important:** Create a new OpenShift project named "pipelines". Do not use the default project. `oc new-project pipelines`
  - `oc create -f ./tekton/`
6. Test the installation by running the minimal pipeline
  -`oc create -f ./hack/pipelinerun.yaml'
7. (Optional) Monitor the pipeline run from the cli. It finish in about 1 minute. `tkn pipelinerun describe --last`
8. Verify that the application is running `curl $(oc get route dockerfile-quickstart -n dockerfile-quickstart -o jsonpath='{.spec.host}') && echo`

# Additional configuration for the ACS pipeline
This addtional configuration is only necessary if you want to run pipelines that use ACS to scan images (i.e. anything beyond the minimal pipeline).

**Important:** IF YOU ARE SETTING THIS UP IN PRODUCTION, DON NOT FOLLOW THESE INSTRUCTIONS. Instead of running `oc whoami -t` Create a user for ACS to use to authenticate, and generate a token for it. a token generated for a user that you created specifically for this purpose. Otherwise the pipeline runs as *your* user, which is probably an admin account.

1. Install ACS following these instructions (select the latest version of ACS from the dropdown at the top of the page) - https://docs.openshift.com/acs/3.72/installing/install-ocp-operator.html#installing-using-an-operator
  - Summary: Install the operator, create a Central CR, generate an init bundle, and create a SecureCluster CR 
2. In the ACS central web console, generate a token
  - Get the URL to the ACS central web console
      `echo "https://$(oc get route pipelines -n pipelines -o jsonpath='{.spec.host}')/"`
  - Browse to central (click the URL in the your terminal)
  - Login with username "admin" and password given by this command:
      `oc -n rhacs-operator get secret central-htpasswd -o go-template='`
  - Platform Configuration → Integrations
  - *Scroll down* to the Authentication Tokens category
  - Select "API Token"
  - Select "Generate Token"
  - Name: tekton
  - Required Level of Access: Continuous Integration
  - Select "Generate"
  - Copy the generated token and store it safely
3. In the terminal, using the `oc` cli, create a Secret for the pipeline to use for ACS scan
```
ROX_CENTRAL_ENDPOINT=$(oc get route central -n stackrox -o jsonpath='{.spec.host}'):443
ROX_API_TOKEN=<token from the ACS UI>
oc create secret generic roxsecrets --from-literal=rox_central_endpoint=${ROX_CENTRAL_ENDPOINT} --from-literal=rox_api_token=${ROX_API_TOKEN}
```
3. Allow ACS to pull images from the "pipelines" namespace
- `oc policy add-role-to-user system:image-puller system:serviceaccount:stackrox:scanner -n pipelines`

## Addtional Configuration for the sigstore pipeline
WARNING: The configuration in this section secures the example namespace by requiring valid signatures on images. Some example pipelines do not sign the images so images built by those pipelines they will stop working. You can always revert the configuration as described below to make them work again.

1. Gereate a key pair for signing images with cosign
 - The command will generate the key pair and create a kubernetes secret named "cosign" for you in the "pipelines" namespace.
 - `cosign generate-key-pair k8s://pipelines/cosign`
 - Enter a password for the private key and then enter the same password again to confirm
2. Configure ACS to verify signatures using the pipeline's public key
  - Get the key with `oc get secret cosign -o jsonpath='{.data.cosign\.pub}' | base64 -d`. The command output should start with "BEGIN PUBLIC KEY".
  - Browse to the ACS Central web console. You can get the URL with `echo "https://$(oc get route central -n stackrox -o jsonpath='{.spec.host}')/"`
  - From the top level menu, select Integrations
  - scroll down -> Sigstore Integrations -> New Integration
  - Integration name: tekton
  - Expand "Cosign"
  - Add new public key
  - Public key name: tekton
  - Paste the output of the oc command above.
  - Save
  - From the top level menu, select Platform Configuration -> Policy Management
  - Create Policy
  - Name: signed-by-pipeline
  - Categories: DevOps Best Practices
  - Click Next
  - Under "Lifecyle staged", make sure the Deploy box is checked
  - Under "Response method", select "Inform and enforce"
  - Under "Configure enforcement behavior" enable the toggle for "Enforce on Deploy"
  - Click Next
  - From the right side, drag "Not verified by trusted image signers" to the box that says "Drop a policy field inside"
  - Click the blue "Select" button
  - Check the box next to "tekton" and click Save
  - Click Next
  - Click "Add inclusion scope"
  - Cluster: mycluster
  - Namespace: nodejs-example (or the namespace you are deploying the test image to if it is different)
  - Click Next
  - Click Save
3. Run the minimal pipeline (which does not sign images). ACS will block the deployment (which is good!)
  - `oc create -f hack/minimal-pipelinerun.yaml`
  - In the OpenShift web console, Workloads -> Deployments -> Make sure te Project dropdown says 'nodejs-example' -> Click the deployment
  - Notice it says Scaled to 0.
  - Click Events. Notice the event that says StackRox (ACS) scaled it down.
  - In the ACS central UI, select Violations from the top menu
  - In the filter box, type Policy and click the box that says "Policy:" that displays below the text box. Continue typing signed-by-pipeline and click the box that displays below that says "signed-by-pipeline".
  - Click the policy in the table that says "signed-by-pipeline"
  - Notice it says "Container 'nodejs-example' image signature is unverified"
4. Run the sigstore pipeline. ACS will allow the deployment because the image is signed.
  - `oc create -f hack/sigstore-pipelinerun.yaml`
5. (Optional) remove the policy so you can run other pipelines again.
  - From the top level menu, select Platform Configuration -> Policy Management
  - Search for Policy: signed-by-pipeline
  - Click the 3 dots on the right -> Disable policy
  - Run the minimal pipeline again to test


## Uninstallation
```
oc delete -f ./tekton/
helm uninstall helm-release
```

## Optional Tasks

### Testing Helm Charts
helm upgrade --install --set image.tag=image-registry.openshift-image-registry.svc:5000/nodejs-example/nodejs-example@sha256:316c66e1d497170623e53f50d5246e83b755f92bc5f6fa248f243c13e56ff862 manual-test ./helm/
helm uninstall manual-test

### Exposing the Internal OpenShift Registry for External Access
- Tell the operator to create a Route to expose the registry
  - `oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge`
- Get the route to the registry
  - `oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}' && echo`
- Get the token of your openshift user to use for logging in
  - `oc whoami -t`
- Run podman/docker commands as normal
  - `podman login <url>`
    - Use the output of `oc whoami` for username, and the output of `oc whoami -t` for password
  - podman push <url>/<openshift project name>/imagename:tag

### Download and configure the roxctl cli
Instructions based on the "roxctl CLI" guide [here](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_security_for_kubernetes/)

1. Download the roxctl binary
curl -s -k -L -H "Authorization: Bearer $ROX_API_TOKEN" \ # Download the cli
		  "https://$ROX_CENTRAL_ENDPOINT/api/cli/download/roxctl-linux" \
		  --output ./roxctl  \
		  > /dev/null
2. Put it on your path somewhere, or update your path to the directory where you downloaded it
3. Configure the connection details. You can paste these commands into the end of your ~/.bash_profile if you do not want to run them at the start of each terminal session. Replace the oc command with the hardcoded value of its outputs if you do.
```
ROX_CENTRAL_ENDPOINT=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}'):443
ROX_API_TOKEN=<Paste the token from the ACS UI. See ACS setup instructions above.>
```
4. When you run roxctl commands, pass $ROX_CENTRAL_ENDPOINT using the -e option. roxctl reads the authentication token from $ROX_API_TOKEN by default.
5. Example command to check an image for vulnerabilities:
 `roxctl image check --insecure-skip-tls-verify -e "$ROX_CENTRAL_ENDPOINT" --image "default-route-openshift-image-registry.apps.x8ccdonr.eastus.aroapp.io/nodejs-example/nodejs-example:manual"

