# Automated Governance Example with Tekton and NodeJS


## Prerequisites
- An OpenShift cluster
- The `oc` cli
- The `tkn` cli (optional)

## Setup
1. Install the OpenShift Pipelines operator
2. `oc new-project nodejs-example`
3. **Important:** Create a new OpenShift project. Do not use the default project. `oc new-project nodejs-example`
4. `oc create -f ./tekton/`
5. Run the pipeline `oc create -f ./hack/pipelinerun.yaml'
6. (Optional) Monitor the pipeline run from the cli. It finish in about 1 minute. `tkn pipelinerun describe --last`
7. Verify that the application is running `curl $(oc get route nodejs-example -o jsonpath='{.spec.host}') && echo`

## Uninstall
`oc delete -f ./tekton/`

## Testing Helm Charts
helm upgrade --install --set image.tag=image-registry.openshift-image-registry.svc:5000/nodejs-example/nodejs-example@sha256:316c66e1d497170623e53f50d5246e83b755f92bc5f6fa248f243c13e56ff862 manual-release ./helm/
helm uninstall manual-release

