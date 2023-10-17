 . ./path.sh
eval $(crc oc-env)
oc login -u kubeadmin https://api.crc.testing:6443
oc new-project fink
