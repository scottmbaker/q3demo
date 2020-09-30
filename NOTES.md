## Notes on running the demo

Notable makefile targets:

```bash
# shut down aether and sdcore-adapter
make demo-down

# bring up aether and sdcore-adapter
make demo-up

# post all demo JSON to aether-roc-api
make demo-post

# shut down sdcore control components up
make sdcore-down

# bring sdcore control components up
make sdcore-up

# run the sd-core UE test a second time (destroys and re-creates test containers)
make sdcore-retest

# POST JSON to directly to the spgwc, 
make sdcore-post

# POST an empty JSON directly to the spgwc.
make sdcore-empty

```

Running the demo:

```bash
# reset everything
make sdcore-down demo-down
make sdcore-up
make sdcore-post
make sdcore-retest  # this should pass
make sdcore-empty
make sdcore-retest  # this should fail

# push JSON using aether-roc
make aether-up
make aether-post
sdalog  # should show JSON pushed to spgwc
make sdcore-retest  # should pass
```


## Notes on using helm 3

My notes so far:
* export HELM_VERSION=v3.2.4
* remove helm init from Makefile
* remove {{ tuple "hss" . | include "omec-control-plane.metadata_labels" | indent 8 }} from job.spec.template.metadata in job-hss-bootstrap.yaml and job-hss-db-sync.yaml
* run kubectl create namespace omec
* ServiceName needs to be added to StatefulSet.spec in oaisim (I made up the service names oaisim-ue and oaisim-enb.
Passed make test now. (edited)
