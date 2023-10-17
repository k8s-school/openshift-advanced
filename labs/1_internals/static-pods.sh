MASTER_NODE=$(kubectl get nodes '--selector=node-role.kubernetes.io/master' -o jsonpath='{.items[0].metadata.name}')
oc debug node/"$MASTER_NODE"
chroot /host
ps -ef | grep "kubelet "
cat /etc/kubernetes/kubelet.conf
cat /etc/kubernetes/manifests/kube-apiserver-pod.yaml | jq