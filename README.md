# Automated Governance Example with Tekton and NodeJS


## Prerequisites
- An OpenShift cluster

## Setup
1. Install the OpenShift Pipelines operator
2. `oc new-project nodejs-example`
3. **Important:** Create a new OpenShift project. Do not use the default project. `oc new-project nodejs-example`
4. `oc create -f ./tekton/`
5. Test the pipeline `oc create -f ./hack/pipelinerun.yaml'
6. Verify that the application is running `curl nodejs-example-nodejs-example.apps.x8ccdonr.eastus.aroapp.io`

## Undeploy App
`oc delete -f ./k8s/`

## Uninstall
`oc delete -f ./tekton/`

