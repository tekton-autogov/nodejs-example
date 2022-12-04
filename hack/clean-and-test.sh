# Uninstall
helm uninstall helm-release
oc delete -f ./tekton/

# Install
oc create -f ./tekton/

# Test
oc create -f ./dockerfile-quickstart/tekton/minimal-pipelinerun.yaml
#oc create -f ./hack/acs-pipelinerun.yaml
#oc create -f ./hack/sigstore-pipelinerun.yaml
#watch tkn pipelinerun describe --last # Watch description of pipeline until it completes
#curl -L $(oc get route dockerfile-quickstart -n dockerfile-quickstart -o jsonpath='{.spec.host}') && echo # Test the route

