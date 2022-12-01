oc delete -f ./k8s/
oc delete -f ./tekton/
oc create -f ./tekton/
oc create -f ./hack/pipelinerun.yaml
watch tkn pipelinerun describe --last
curl $(oc get route nodejs-example -o jsonpath='{.spec.host}') && echo

