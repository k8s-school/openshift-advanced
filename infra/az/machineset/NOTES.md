# Documentation
https://docs.openshift.com/container-platform/4.14/machine_management/creating_machinesets/creating-machineset-azure.html

# Monitoring
```
kubectl get machineset -A
kubectl get machines -A
kubectl get node
```

and then use 'kubectl describe'

### Trough web interface

Have a look at the:
- openshift console
- azure console

## In openshift-machine-api namespace

### Get events:
```
kubectl get event -n openshift-machine-api | grep "Updated machine"
kubectl get event -n openshift-machine-api | grep school
```

### Get controller and operator logs

## In openshift-cloud-controller-manager namespace

### Monitor VMs
```
kubectl logs -n openshift-cloud-controller-manager azure-cloud-node-manager-ff6n7
```

### Get controller logs

WARN: only one of these two is working at a time

```
kubectl logs -n openshift-cloud-controller-manager azure-cloud-controller-manager-5b9c876ddb-sf5pz
kubectl logs -n openshift-cloud-controller-manager azure-cloud-controller-manager-5b9c876ddb-5mgnv
```