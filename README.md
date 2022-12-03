# Automated Governance Example with Tekton and NodeJS


## Prerequisites
- An OpenShift cluster
- The `oc` cli
- The `tkn` cli (optional)

## Setup
1. Install the OpenShift Pipelines operator
2. Install ACS following these instructions - https://docs.openshift.com/acs/3.72/installing/install-ocp-operator.html#installing-using-an-operator
  - Summary: Install the operator, create a Central CR, generate an init bundle, and create a SecureCluster CR 
3. `oc new-project nodejs-example`
4. **Important:** Create a new OpenShift project. Do not use the default project. `oc new-project nodejs-example`
5. `oc create -f ./tekton/`
6. Run the pipeline `oc create -f ./hack/pipelinerun.yaml'
7. (Optional) Monitor the pipeline run from the cli. It finish in about 1 minute. `tkn pipelinerun describe --last`
8. Verify that the application is running `curl $(oc get route nodejs-example -o jsonpath='{.spec.host}') && echo`

## Uninstall
```
oc delete -f ./tekton/
helm uninstall helm-release
```

## Testing Helm Charts
helm upgrade --install --set image.tag=image-registry.openshift-image-registry.svc:5000/nodejs-example/nodejs-example@sha256:316c66e1d497170623e53f50d5246e83b755f92bc5f6fa248f243c13e56ff862 manual-test ./helm/
helm uninstall manual-test

