# openshift-install

## What does the installer 'destroy' cmd?

Undocumented, and debug log are not useful
"openshift-install destroy -h" does not help

Having a look at the code it seems it stop and then remove the VMs.
See https://github.com/openshift/installer/blob/master/cmd/openshift-install/destroy.go
and https://github.com/openshift/installer/blob/dd15963db02cabddf2c26870d230bd1fbbaddb0c/pkg/destroy/ovirt/destroyer.go#L63C2-L63C24

# Machine api

## How to troubleshoot machine-api?

Explanation for the "orphan machine" use case (creation of of machine using the export of an existing machine in a machineset) is available [here](./infra/az/machineset/failure-examples).

## Machine-api operator documentation:

https://github.com/openshift/machine-api-operator/tree/master#readme
