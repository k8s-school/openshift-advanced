#!/bin/bash

# Script to create a new MachineSet based on an existing MachineSet
# Usage: ./create-machineset.sh

set -e  # Stop script on error

echo "🔍 Auto-detecting project name..."

# Calculate project name automatically
PROJECT=$(kubectl get machinesets.machine.openshift.io -n openshift-machine-api -o jsonpath="{.items[1].metadata.labels.machine\.openshift\.io\/cluster-api-cluster}")

if [ -z "$PROJECT" ]; then
    echo "❌ Error: Unable to detect project name"
    echo "Check that MachineSets exist in the cluster"
    exit 1
fi

echo "✅ Project detected: $PROJECT"

# Define source MachineSet name (the working one)
SOURCE_MACHINESET="${PROJECT}-worker-francecentral3"

# Define new MachineSet name
NEW_MACHINESET="${PROJECT}-worker-k8sschool"

echo "📋 Parameters:"
echo "  - Source MachineSet: $SOURCE_MACHINESET"
echo "  - New MachineSet: $NEW_MACHINESET"
echo "  - Zone: 3 → 1"

# Check that source MachineSet exists
echo "🔍 Checking source MachineSet existence..."
if ! oc get machineset "$SOURCE_MACHINESET" -n openshift-machine-api >/dev/null 2>&1; then
    echo "❌ Error: Source MachineSet '$SOURCE_MACHINESET' does not exist"
    echo "Available MachineSets:"
    oc get machinesets -n openshift-machine-api
    exit 1
fi

echo "✅ Source MachineSet found"

# Check if new MachineSet already exists
if oc get machineset "$NEW_MACHINESET" -n openshift-machine-api >/dev/null 2>&1; then
    echo "⚠️  MachineSet '$NEW_MACHINESET' already exists"
    read -p "Do you want to delete and recreate it? (y/N): " confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        echo "🗑️  Deleting existing MachineSet..."
        oc delete machineset "$NEW_MACHINESET" -n openshift-machine-api
        echo "⏳ Waiting for complete deletion..."
        sleep 5
    else
        echo "❌ Operation cancelled"
        exit 1
    fi
fi

echo "🚀 Creating new MachineSet..."

# Create new MachineSet
oc get machineset "$SOURCE_MACHINESET" -n openshift-machine-api -o yaml | \
sed "s/${PROJECT}-worker-francecentral3/${PROJECT}-worker-k8sschool/g" | \
sed 's/francecentral3/k8sschool/g' | \
sed 's/zone: "3"/zone: "1"/g' | \
oc apply -f -

echo "✅ MachineSet created successfully!"

echo "📊 Checking status..."
echo "MachineSets:"
oc get machinesets -n openshift-machine-api

echo ""
echo "Machines:"
oc get machines -n openshift-machine-api

echo ""
echo "🔄 To monitor new node creation, use:"
echo "watch 'oc get machines -n openshift-machine-api; echo; oc get nodes'"

echo ""
echo "📝 The new node should appear in 5-15 minutes"
