## Notes on running the demo

Note: Run the following before running any makefile targets.

```bash
source env.sh
```

Notable makefile targets:

```bash
# shut down aether and sdcore-adapter
make demo-down

# bring up aether and sdcore-adapter
make demo-up

# post all demo JSON to aether-roc-api
make demo-post

# change the subscriber to the wrong user-plane profile
make demo-wrong-up

# change the subscriber to the correct user-plane-profile
make demo-right-up

# set the subscriber's enabled bit to false
make demo-disabled

# set the subscriber's enable bit back to true
make demo-enabled

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
make sdcore-retest  # this should fail as no subscriber is configured

# push JSON using aether-roc
make demo-up
make demo-post
sdalog  # should show JSON pushed to spgwc
make sdcore-retest  # should pass

# change the user-plane profile
make demo-wrong-up
make sdcore-retest  # this should fail

# change the user-plane profile back to the correct one
make demo-right-up
make sdcore-retest  $ this should succeed

```


## Notes on using helm 3

My notes so far:
* export HELM_VERSION=v3.2.4
* remove helm init from Makefile
* remove {{ tuple "hss" . | include "omec-control-plane.metadata_labels" | indent 8 }} from job.spec.template.metadata in job-hss-bootstrap.yaml and job-hss-db-sync.yaml
* run kubectl create namespace omec
* ServiceName needs to be added to StatefulSet.spec in oaisim (I made up the service names oaisim-ue and oaisim-enb.
Passed make test now. (edited)
