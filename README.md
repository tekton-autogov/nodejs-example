# Automated Governance Example with Tekton and NodeJS


## Prerequisites
- An OpenShift cluster
- The `oc` cli
- The `tkn` cli (Optional)
- The cosign cli (Optional. Requred if you want to run the sigstore pipeline). See the [installation docs](https://docs.sigstore.dev/cosign/installation/).

## Installation
1. Install the OpenShift Pipelines operator
3. `oc new-project nodejs-example`
4. **Important:** Create a new OpenShift project named "nodejs-example". Do not use the default project. `oc new-project nodejs-example`
  - `oc create -f ./tekton/`
6. Test the installation by running the minimal pipeline
  -`oc create -f ./hack/pipelinerun.yaml'
7. (Optional) Monitor the pipeline run from the cli. It finish in about 1 minute. `tkn pipelinerun describe --last`
8. Verify that the application is running `curl $(oc get route nodejs-example -o jsonpath='{.spec.host}') && echo`

# Additional configuration for the ACS pipeline
This addtional configuration is only necessary if you want to run pipelines that use ACS to scan images (i.e. anything beyond the minimal pipeline).

**Important:** IF YOU ARE SETTING THIS UP IN PRODUCTION, DON NOT FOLLOW THESE INSTRUCTIONS. Instead of running `oc whoami -t` Create a user for ACS to use to authenticate, and generate a token for it. a token generated for a user that you created specifically for this purpose. Otherwise the pipeline runs as *your* user, which is probably an admin account.

1. Install ACS following these instructions (select the latest version of ACS from the dropdown at the top of the page) - https://docs.openshift.com/acs/3.72/installing/install-ocp-operator.html#installing-using-an-operator
  - Summary: Install the operator, create a Central CR, generate an init bundle, and create a SecureCluster CR 
2. In the ACS central web console, generate a token
  - Get the URL to the ACS central web console
      `echo "https://$(oc get route nodejs-example -n nodejs-example -o jsonpath='{.spec.host}')/"`
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
ROX_CENTRAL_ENDPOINT=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}'):443
ROX_API_TOKEN=<token from the ACS UI>
oc create secret generic roxsecrets --from-literal=rox_central_endpoint=${ROX_CENTRAL_ENDPOINT} --from-literal=rox_api_token=${ROX_API_TOKEN}
```

## Addtional Configuration for the sigstore pipeline
1. `cosign generate-keypair` # Skip the password
- Use a password
- Save the generated files.
- DO NOT accidentally commit your .key file with git and upload it to the Internet.
2. `oc create secret generic cosign --from-file=cosign.key --from-file=cosign.pub --from-literal=password=<the password you just set>`
- If you do not want to enter your password as part of the command, run the command without the --from-literal argument and add the password to the secret after it is created. In that case, base64 encode the password, run `oc edit secret cosign` and add a line below the 'cosign.pub' entry like 'password: <base64 encoded value>'. Remember to indent the new line to match the one above it.

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

