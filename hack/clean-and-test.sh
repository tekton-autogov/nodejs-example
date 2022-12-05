# Uninstall
#helm uninstall dockerfile-quickstart
oc delete -f ./tekton/

# Install
oc create -f ./tekton/

# Test
oc create -f ./dockerfile-quickstart/tekton/dockerfile-minimal-pipelinerun.yaml
oc create -f ./nodejs-quickstart/tekton/dockerfile-minimal-pipelinerun.yaml
oc create -f ./spring-boot-quickstart/tekton/java-minimal-pipelinerun.yaml
oc create -f ./go-quickstart/tekton/dockerfile-minimal-pipelinerun.yaml
#watch tkn pipelinerun describe --last # Watch description of pipeline until it completes
#curl -L $(oc get route dockerfile-quickstart -n dockerfile-quickstart -o jsonpath='{.spec.host}') && echo # Test the route

