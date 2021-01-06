Data Migration Demo

1) Ensure the v1 models are located in demo-gnmi-v1 subdirectory

```
make  get-gnmi-models
```

2) Execute the following to load the v1 models:

```
make sdcore-adapter-topo-v1
make demo-gnmi-v1
```

3) Show onos-gui, there should be approximately 5 v1 models

4) Enter the sdcore-adapter container and run the following

```
/usr/local/bin/sdcore-migrate -from-target connectivity-service-v1 -from-version 1.0.0 -to-target connectivity-service-v2 -to-version 2.0.0 -aether-config onos-config:5150 -client_key=/etc/sdcore-adapter/certs/tls.key -client_crt=/etc/sdcore-adapter/certs/tls.crt -ca_crt=/etc/sdcore-adapter/certs/tls.cacert -hostCheckDisabled
```

5) Look at onos-gui. The v2 models should be created and the v1 models deleted.
