# Uninstall
helm uninstall helm-release
oc delete -f ./tekton/

# Install
oc create -f ./tekton/

# Test
oc create -f ./hack/pipelinerun.yaml
watch tkn pipelinerun describe --last
curl -L $(oc get route nodejs-example -o jsonpath='{.spec.host}') && echo

