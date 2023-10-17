# Use 'crc start' to retrieve credentials

LOGIN=kubeadmin
eval $(crc oc-env)
oc login -u $LOGIN https://api.crc.testing:6443
