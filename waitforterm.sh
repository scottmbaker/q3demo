#!/bin/bash
NAMESPACE=$1
PODS=`kubectl -n $NAMESPACE get pods | grep -i terminating`
while [[ $PODS != "" ]]; do
    echo "waiting for pods to terminate"
    sleep 1s
    PODS=`kubectl -n $NAMESPACE get pods | grep -i terminating`
done
