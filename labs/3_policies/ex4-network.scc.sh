oc adm policy add-scc-to-user anyuid -z default --dry-run -o yaml

# WARN: add scc to all namespaces
kubectl describe clusterrolebindings. system:openshift:scc:anyuid
