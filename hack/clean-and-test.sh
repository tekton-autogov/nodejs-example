oc delete -f ./k8s/
oc delete -f ./tekton/
oc create -f ./tekton/
oc create -f ./hack/pipelinerun.yaml
