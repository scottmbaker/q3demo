#!/bin/bash

# wrote this becase the following:
#   kubectl wait pod -n micro-onos --for=condition=Ready --all
# kept hanging on me even when all  pods are ready

NAMESPACE=$1
REGEX=$2

POD=""
while [[ "$POD" == "" ]]; do
    POD=$(kubectl -n $NAMESPACE get pods --field-selector status.phase=Running -o name | grep -i $REGEX)
    echo "Waiting for pod $REGEX in namespace $NAMESPACE"
    sleep 1s
done

echo "$POD is running"

while [[ $(kubectl -n $NAMESPACE get $POD -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod $POD to be ready" && sleep 1; done

echo "$POD is ready"
