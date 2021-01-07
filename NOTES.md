## Notes

Notable makefile targets:

```bash
# Bootstrap the devel env before first use
make bootstrap

# Bring up a k3d cluster with 3 worker nodes
make k3d-cluster-up K3D_AGENTS=3

# bring up Atomix and the ROC
make aether-up

# Connect sdcore-adapter device to onos-config
make sdcore-adapter-topo

# Load some models into the v1.0.0 API
make demo-post-1.0.0

# Load some models into the v2.0.0 API
make demo-post-2.0.0

# tear down Atomix and the ROC
make aether-down

# Tear down the k3d cluster
make k3d-cluster-down
```
