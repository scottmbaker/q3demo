# Aether ROC Development

This repository contains a Makefile and scripts for conveniently bringing up the Aether ROC
in a local development environment based on [k3d](https://k3d.io/).

## Prerequisites

Install the following tools on your development machine:
* Docker: https://docs.docker.com/get-docker/
* k3d: https://k3d.io/#installation
* kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl/
* Helm: https://helm.sh/docs/intro/install/

## Bootstrap

Before bringing up the ROC for the first time, it's necessary to run:

```bash
make bootstrap       # download the Aether ROC Helm charts and their dependencies
```

## Bringing up the ROC

Here's a simple workflow for bringing up the ROC and populating some sample models:

```bash
source env.sh        # set a couple of environment vars
make k3d-cluster-up  # bring up a single-node k3d cluster
make aether-up       # install the Aether ROC
make demo-post       # load some sample models into the ROC
```

Descriptions of the important Makefile targets can be found in [NOTES.md](NOTES.md).

## Interacting with the ROC

Assuming you have deployed the k3d cluster as described above, the ROC and ONOS are
available on localhost:
* ROC GUI: http://localhost:31190/
* ONOS GUI: http://localhost:31180/
* ROC API: http://localhost:31190/aether-roc-api/
