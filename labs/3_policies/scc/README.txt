Play with fink-alert-simulator
Which scc does it use (beware the pod is launched by argo-workflow, so it uses default sa)
Why is runAsUser changed:
oc get pod -o jsonpath='{range .items[*]}{@.metadata.name}{" runAsUser: "}{@.spec.containers[*].securityContext.runAsUser}{" fsGroup: "}{@.spec.securityContext.fsGroup}
kubectl get ns -o yaml # watch annotation

# Solution
oc adm policy add-scc-to-user anyuid -z default


# Tracks about scc future
https://github.com/redhat-openshift-ecosystem/community-operators-prod/discussions/1417
It seems it will move to podsecurity admission
