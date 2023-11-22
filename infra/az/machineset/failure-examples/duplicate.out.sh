[openshift@openshift ~]$ kubectl get machine -n openshift-machine-api  demo-swfz8-worker-francecentral3-kgflv -o yaml > duplicate.yaml
# Perform some edit on duplicate.yaml, remove status and change machine name

[openshift@openshift ~]$ kubectl get -n openshift-machine-api machinesets.machine.openshift.io demo-swfz8-worker-francecentral3
NAME                               DESIRED   CURRENT   READY   AVAILABLE   AGE
demo-swfz8-worker-francecentral3   1         1         1       1           47m

[openshift@openshift ~]$ kubectl apply -f duplicate.yaml
machine.machine.openshift.io/demo-swfz8-worker-francecentral3-school created

[openshift@openshift ~]$ kubectl get machinesets.machine.openshift.io -A
NAMESPACE               NAME                               DESIRED   CURRENT   READY   AVAILABLE   AGE
openshift-machine-api   demo-swfz8-worker-francecentral1   0         0                             45m
openshift-machine-api   demo-swfz8-worker-francecentral2   0         0                             45m
openshift-machine-api   demo-swfz8-worker-francecentral3   1         1         1       1           45m

[openshift@openshift ~]$ kubectl logs  -n openshift-machine-api machine-api-controllers-58d8d5b789-w8zcq | tail -n 20
## Defaulted container "machineset-controller" out of: machineset-controller, machine-controller, nodelink-controller, machine-healthcheck-controller, kube-rbac-proxy-machineset-mtrc, kube-rbac-proxy-machine-mtrc, kube-rbac-proxy-mhc-mtrc
I1122 20:45:08.279380       1 machine_webhook.go:528] Mutate webhook called for Machine: demo-swfz8-worker-francecentral3-school
I1122 20:45:08.279401       1 machine_webhook.go:796] Defaulting Azure providerSpec
## I1122 20:45:08.294308       1 machine_webhook.go:472] Validate webhook called for Machine: demo-swfz8-worker-francecentral3-school
I1122 20:45:08.294329       1 machine_webhook.go:857] Validating Azure providerSpec
## I1122 20:45:08.311087       1 controller.go:302] Too many replicas for machine.openshift.io/v1beta1, Kind=MachineSet openshift-machine-api/demo-swfz8-worker-francecentral3, need 1, deleting 1
## I1122 20:45:08.311216       1 controller.go:309] Found  delete policy
I1122 20:45:08.454505       1 machineset_webhook.go:118] Validate webhook called for MachineSet: demo-swfz8-worker-francecentral3
I1122 20:45:08.454548       1 machine_webhook.go:857] Validating Azure providerSpec
I1122 20:45:08.464871       1 machineset_webhook.go:118] Validate webhook called for MachineSet: demo-swfz8-worker-francecentral3
I1122 20:45:08.464913       1 machine_webhook.go:857] Validating Azure providerSpec
I1122 20:45:08.476296       1 machineset_webhook.go:118] Validate webhook called for MachineSet: demo-swfz8-worker-francecentral3
I1122 20:45:08.476341       1 machine_webhook.go:857] Validating Azure providerSpec
I1122 20:45:08.610233       1 machine_webhook.go:494] Validate webhook called for Machine: demo-swfz8-worker-francecentral3-school
I1122 20:45:08.610745       1 machine_webhook.go:857] Validating Azure providerSpec
I1122 20:45:09.085421       1 machine_webhook.go:494] Validate webhook called for Machine: demo-swfz8-worker-francecentral3-school
I1122 20:45:09.085985       1 machine_webhook.go:857] Validating Azure providerSpec
I1122 20:45:09.649038       1 machine_webhook.go:494] Validate webhook called for Machine: demo-swfz8-worker-francecentral3-school
I1122 20:45:09.649710       1 machine_webhook.go:857] Validating Azure providerSpec
I1122 20:45:09.818749       1 machine_webhook.go:494] Validate webhook called for Machine: demo-swfz8-worker-francecentral3-school
## E1122 20:45:09.832480       1 controller.go:119] Unable to retrieve Machine openshift-machine-api/demo-swfz8-worker-francecentral3-school from store: Machine.machine.openshift.io "demo-swfz8-worker-francecentral3-school" not found


[openshift@openshift ~]$ kubectl logs  -n openshift-machine-api machine-api-controllers-58d8d5b789-w8zcq -c machine-controller  | tail -n 90
I1122 20:49:16.322718       1 controller.go:90] controllers/MachineSet "msg"="Reconciling" "machineset"="demo-swfz8-worker-francecentral2" "namespace"="openshift-machine-api"
I1122 20:49:16.322792       1 controller.go:141] demo-swfz8-worker-francecentral2: Reconciling MachineSet
I1122 20:49:16.337800       1 controller.go:90] controllers/MachineSet "msg"="Reconciling" "machineset"="demo-swfz8-worker-francecentral3" "namespace"="openshift-machine-api"
I1122 20:49:16.338000       1 controller.go:141] demo-swfz8-worker-francecentral3: Reconciling MachineSet
## I1122 20:49:29.765642       1 controller.go:156] demo-swfz8-worker-francecentral3-school: reconciling Machine
## I1122 20:49:29.765674       1 actuator.go:221] demo-swfz8-worker-francecentral3-school: actuator checking if machine exists
I1122 20:49:29.893410       1 controller.go:90] controllers/MachineSet "msg"="Reconciling" "machineset"="demo-swfz8-worker-francecentral3" "namespace"="openshift-machine-api"
I1122 20:49:29.893485       1 controller.go:141] demo-swfz8-worker-francecentral3: Reconciling MachineSet
I1122 20:49:29.913837       1 controller.go:90] controllers/MachineSet "msg"="Reconciling" "machineset"="demo-swfz8-worker-francecentral3" "namespace"="openshift-machine-api"
## I1122 20:49:29.913909       1 controller.go:141] demo-swfz8-worker-francecentral3: Reconciling MachineSet
## W1122 20:49:29.939476       1 virtualmachines.go:100] vm demo-swfz8-worker-francecentral3-school not found: %!w(string=compute.VirtualMachinesClient#Get: Failure responding to request: StatusCode=404 -- Original Error: autorest/azure: Service returned an error. Status=404 Code="ResourceNotFound" Message="The Resource 'Microsoft.Compute/virtualMachines/demo-swfz8-worker-francecentral3-school' under resource group 'demo-swfz8-rg' was not found. For more details please go to https://aka.ms/ARMResourceNotFoundFix")
I1122 20:49:29.939504       1 controller.go:404] demo-swfz8-worker-francecentral3-school: going into phase "Failed"
I1122 20:49:29.971269       1 controller.go:156] demo-swfz8-worker-francecentral3-school: reconciling Machine
## I1122 20:49:29.971298       1 controller.go:404] demo-swfz8-worker-francecentral3-school: going into phase "Deleting"
I1122 20:49:29.983898       1 controller.go:200] demo-swfz8-worker-francecentral3-school: reconciling machine triggers delete
## I1122 20:49:29.983948       1 controller.go:204] demo-swfz8-worker-francecentral3-school: waiting for node to be drained before deleting instance
I1122 20:49:29.984032       1 controller.go:156] demo-swfz8-worker-francecentral3-school: reconciling Machine
I1122 20:49:29.984045       1 controller.go:404] demo-swfz8-worker-francecentral3-school: going into phase "Deleting"
I1122 20:49:29.985051       1 recorder.go:104] events "msg"="Node drain skipped" "object"={"kind":"Machine","namespace":"openshift-machine-api","name":"demo-swfz8-worker-francecentral3-school","uid":"fba96033-b220-4c3f-9b38-eb3beb2cb492","apiVersion":"machine.openshift.io/v1beta1","resourceVersion":"38884"} "reason"="DrainSkipped" "type"="Normal"
I1122 20:49:30.004587       1 controller.go:200] demo-swfz8-worker-francecentral3-school: reconciling machine triggers delete
I1122 20:49:30.004623       1 controller.go:204] demo-swfz8-worker-francecentral3-school: waiting for node to be drained before deleting instance
I1122 20:49:30.004744       1 controller.go:156] demo-swfz8-worker-francecentral3-school: reconciling Machine
E1122 20:49:30.007540       1 controller.go:324]  "msg"="Reconciler error" "error"="could not update machine status: Operation cannot be fulfilled on machines.machine.openshift.io \"demo-swfz8-worker-francecentral3-school\": the object has been modified; please apply your changes to the latest version and try again" "controller"="machine-drain-controller" "name"="demo-swfz8-worker-francecentral3-school" "namespace"="openshift-machine-api" "object"={"name":"demo-swfz8-worker-francecentral3-school","namespace":"openshift-machine-api"} "reconcileID"="033d8ecf-782c-4787-9765-6159d49dcc76"
I1122 20:49:30.007741       1 recorder.go:104] events "msg"="Node drain skipped" "object"={"kind":"Machine","namespace":"openshift-machine-api","name":"demo-swfz8-worker-francecentral3-school","uid":"fba96033-b220-4c3f-9b38-eb3beb2cb492","apiVersion":"machine.openshift.io/v1beta1","resourceVersion":"38885"} "reason"="DrainSkipped" "type"="Normal"
I1122 20:49:30.021072       1 controller.go:200] demo-swfz8-worker-francecentral3-school: reconciling machine triggers delete
I1122 20:49:30.021122       1 controller.go:204] demo-swfz8-worker-francecentral3-school: waiting for node to be drained before deleting instance
I1122 20:49:30.021171       1 controller.go:156] demo-swfz8-worker-francecentral3-school: reconciling Machine
I1122 20:49:30.032183       1 controller.go:200] demo-swfz8-worker-francecentral3-school: reconciling machine triggers delete
I1122 20:49:30.032203       1 actuator.go:144] Deleting machine demo-swfz8-worker-francecentral3-school
I1122 20:49:30.032660       1 virtualmachines.go:348] deleting vm demo-swfz8-worker-francecentral3-school
I1122 20:49:30.440633       1 virtualmachines.go:365] successfully deleted vm demo-swfz8-worker-francecentral3-school
I1122 20:49:30.440658       1 disks.go:50] deleting disk demo-swfz8-worker-francecentral3-school_OSDisk
I1122 20:49:30.553304       1 disks.go:66] successfully deleted disk demo-swfz8-worker-francecentral3-school_OSDisk
I1122 20:49:30.553327       1 networkinterfaces.go:328] deleting nic demo-swfz8-worker-francecentral3-school-nic
I1122 20:49:30.688621       1 networkinterfaces.go:347] successfully deleted nic demo-swfz8-worker-francecentral3-school-nic
I1122 20:49:30.799838       1 machine_scope.go:240] demo-swfz8-worker-francecentral3-school: patching machine
I1122 20:49:30.836380       1 actuator.go:221] demo-swfz8-worker-francecentral3-school: actuator checking if machine exists
I1122 20:49:30.836565       1 recorder.go:104] events "msg"="Deleted machine \"demo-swfz8-worker-francecentral3-school\"" "object"={"kind":"Machine","namespace":"openshift-machine-api","name":"demo-swfz8-worker-francecentral3-school","uid":"fba96033-b220-4c3f-9b38-eb3beb2cb492","apiVersion":"machine.openshift.io/v1beta1","resourceVersion":"38887"} "reason"="Deleted" "type"="Normal"
W1122 20:49:31.332339       1 virtualmachines.go:100] vm demo-swfz8-worker-francecentral3-school not found: %!w(string=compute.VirtualMachinesClient#Get: Failure responding to request: StatusCode=404 -- Original Error: autorest/azure: Service returned an error. Status=404 Code="ResourceNotFound" Message="The Resource 'Microsoft.Compute/virtualMachines/demo-swfz8-worker-francecentral3-school' under resource group 'demo-swfz8-rg' was not found. For more details please go to https://aka.ms/ARMResourceNotFoundFix")
E1122 20:49:31.340375       1 controller.go:251] demo-swfz8-worker-francecentral3-school: failed to remove finalizer from machine: Operation cannot be fulfilled on machines.machine.openshift.io "demo-swfz8-worker-francecentral3-school": the object has been modified; please apply your changes to the latest version and try again
E1122 20:49:31.340486       1 controller.go:324]  "msg"="Reconciler error" "error"="Operation cannot be fulfilled on machines.machine.openshift.io \"demo-swfz8-worker-francecentral3-school\": the object has been modified; please apply your changes to the latest version and try again" "controller"="machine-controller" "name"="demo-swfz8-worker-francecentral3-school" "namespace"="openshift-machine-api" "object"={"name":"demo-swfz8-worker-francecentral3-school","namespace":"openshift-machine-api"} "reconcileID"="3c2a0edf-26b2-473b-9ac0-f1b153c3eec2"
I1122 20:49:31.340556       1 controller.go:156] demo-swfz8-worker-francecentral3-school: reconciling Machine
I1122 20:49:31.351872       1 controller.go:200] demo-swfz8-worker-francecentral3-school: reconciling machine triggers delete
I1122 20:49:31.351895       1 actuator.go:144] Deleting machine demo-swfz8-worker-francecentral3-school
I1122 20:49:31.352349       1 virtualmachines.go:348] deleting vm demo-swfz8-worker-francecentral3-school
I1122 20:49:31.633472       1 virtualmachines.go:365] successfully deleted vm demo-swfz8-worker-francecentral3-school
I1122 20:49:31.633502       1 disks.go:50] deleting disk demo-swfz8-worker-francecentral3-school_OSDisk
I1122 20:49:31.739208       1 disks.go:66] successfully deleted disk demo-swfz8-worker-francecentral3-school_OSDisk
I1122 20:49:31.739231       1 networkinterfaces.go:328] deleting nic demo-swfz8-worker-francecentral3-school-nic
I1122 20:49:31.869701       1 networkinterfaces.go:347] successfully deleted nic demo-swfz8-worker-francecentral3-school-nic
I1122 20:49:31.906903       1 machine_scope.go:224] demo-swfz8-worker-francecentral3-school: status unchanged
I1122 20:49:31.906958       1 machine_scope.go:240] demo-swfz8-worker-francecentral3-school: patching machine
I1122 20:49:31.936339       1 actuator.go:221] demo-swfz8-worker-francecentral3-school: actuator checking if machine exists
I1122 20:49:31.936464       1 recorder.go:104] events "msg"="Deleted machine \"demo-swfz8-worker-francecentral3-school\"" "object"={"kind":"Machine","namespace":"openshift-machine-api","name":"demo-swfz8-worker-francecentral3-school","uid":"fba96033-b220-4c3f-9b38-eb3beb2cb492","apiVersion":"machine.openshift.io/v1beta1","resourceVersion":"38893"} "reason"="Deleted" "type"="Normal"
W1122 20:49:32.085407       1 virtualmachines.go:100] vm demo-swfz8-worker-francecentral3-school not found: %!w(string=compute.VirtualMachinesClient#Get: Failure responding to request: StatusCode=404 -- Original Error: autorest/azure: Service returned an error. Status=404 Code="ResourceNotFound" Message="The Resource 'Microsoft.Compute/virtualMachines/demo-swfz8-worker-francecentral3-school' under resource group 'demo-swfz8-rg' was not found. For more details please go to https://aka.ms/ARMResourceNotFoundFix")
I1122 20:49:32.106133       1 controller.go:255] demo-swfz8-worker-francecentral3-school: machine deletion successful
I1122 20:59:16.064158       1 controller.go:156] demo-swfz8-master-0: reconciling Machine
I1122 20:59:16.064186       1 actuator.go:221] demo-swfz8-master-0: actuator checking if machine exists
I1122 20:59:16.381067       1 reconciler.go:458] Provisioning state is 'Succeeded' for machine demo-swfz8-master-0
I1122 20:59:16.381101       1 controller.go:282] demo-swfz8-master-0: reconciling machine triggers idempotent update
I1122 20:59:16.381109       1 actuator.go:180] Updating machine demo-swfz8-master-0
I1122 20:59:16.680576       1 machine_scope.go:224] demo-swfz8-master-0: status unchanged
I1122 20:59:16.680627       1 machine_scope.go:240] demo-swfz8-master-0: patching machine
I1122 20:59:16.724172       1 controller.go:156] demo-swfz8-master-1: reconciling Machine
I1122 20:59:16.724197       1 actuator.go:221] demo-swfz8-master-1: actuator checking if machine exists
I1122 20:59:16.930702       1 reconciler.go:458] Provisioning state is 'Succeeded' for machine demo-swfz8-master-1
I1122 20:59:16.930739       1 controller.go:282] demo-swfz8-master-1: reconciling machine triggers idempotent update
I1122 20:59:16.930748       1 actuator.go:180] Updating machine demo-swfz8-master-1
I1122 20:59:17.297408       1 machine_scope.go:224] demo-swfz8-master-1: status unchanged
I1122 20:59:17.297486       1 machine_scope.go:240] demo-swfz8-master-1: patching machine
I1122 20:59:17.338397       1 controller.go:156] demo-swfz8-master-2: reconciling Machine
I1122 20:59:17.338418       1 actuator.go:221] demo-swfz8-master-2: actuator checking if machine exists
I1122 20:59:17.536261       1 reconciler.go:458] Provisioning state is 'Succeeded' for machine demo-swfz8-master-2
I1122 20:59:17.536295       1 controller.go:282] demo-swfz8-master-2: reconciling machine triggers idempotent update
I1122 20:59:17.536302       1 actuator.go:180] Updating machine demo-swfz8-master-2
I1122 20:59:17.797907       1 machine_scope.go:224] demo-swfz8-master-2: status unchanged
I1122 20:59:17.797963       1 machine_scope.go:240] demo-swfz8-master-2: patching machine
I1122 20:59:17.843499       1 controller.go:156] demo-swfz8-worker-francecentral3-kgflv: reconciling Machine
I1122 20:59:17.843522       1 actuator.go:221] demo-swfz8-worker-francecentral3-kgflv: actuator checking if machine exists
I1122 20:59:18.043012       1 reconciler.go:458] Provisioning state is 'Succeeded' for machine demo-swfz8-worker-francecentral3-kgflv
I1122 20:59:18.043043       1 controller.go:282] demo-swfz8-worker-francecentral3-kgflv: reconciling machine triggers idempotent update
I1122 20:59:18.043051       1 actuator.go:180] Updating machine demo-swfz8-worker-francecentral3-kgflv
I1122 20:59:18.366199       1 machine_scope.go:224] demo-swfz8-worker-francecentral3-kgflv: status unchanged
I1122 20:59:18.366307       1 machine_scope.go:240] demo-swfz8-worker-francecentral3-kgflv: patching machine
I1122 21:00:10.404292       1 controller.go:90] controllers/MachineSet "msg"="Reconciling" "machineset"="demo-swfz8-worker-francecentral1" "namespace"="openshift-machine-api"
I1122 21:00:10.404366       1 controller.go:141] demo-swfz8-worker-francecentral1: Reconciling MachineSet
I1122 21:00:10.435177       1 controller.go:90] controllers/MachineSet "msg"="Reconciling" "machineset"="demo-swfz8-worker-francecentral2" "namespace"="openshift-machine-api"
I1122 21:00:10.435234       1 controller.go:141] demo-swfz8-worker-francecentral2: Reconciling MachineSet
I1122 21:00:10.451689       1 controller.go:90] controllers/MachineSet "msg"="Reconciling" "machineset"="demo-swfz8-worker-francecentral3" "namespace"="openshift-machine-api"
I1122 21:00:10.451739       1 controller.go:141] demo-swfz8-worker-francecentral3: Reconciling MachineSet

