# Uninstall
helm uninstall helm-release
oc delete -f ./tekton/

# Install
oc create -f ./tekton/

# Test
oc create -f ./hack/pipelinerun.yaml
watch -b tkn pipelinerun describe --last # Watch description of pipeline until it completes
tkn pipelinerun describe --last # Print description of pipeline after watch exists so that it stays on screen
curl -L $(oc get route nodejs-example -o jsonpath='{.spec.host}') && echo # Test the route

