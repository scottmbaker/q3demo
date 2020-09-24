SDRAN_HELM_DIR=./sdran-helm-charts

download-scripts:
	rm -rf /tmp/scott-misc
	git clone http://github.com/sbconsulting/misc /tmp/scott-misc
	sudo cp /tmp/scott-misc/aether-scripts/* /usr/bin

sdcore-adapter-up:
	(helm ls -n micro-onos | grep sdcore-adapter) || helm install -n micro-onos sdcore-adapter ${SDRAN_HELM_DIR}/sdcore-adapter -f sdcore-adapter-override.yaml

sdcore-adapter-down:
	((helm ls -n micro-onos | grep sdcore-adapter) && helm del -n micro-onos sdcore-adapter) || true

sdcore-adapter-topo:
	occli topo add device spgw-1 --address sdcore-adapter:5150 --role leaf --type Aether --version 1.0.0

sdcore-adapter-reinstall: sdcore-adapter-down sdcore-adapter-up

aether-up: 
	(helm ls -n micro-onos | grep onos-umbrella) || helm -n micro-onos install onos-umbrella onosproject/onos-umbrella -f values-override.yaml

aether-down:
	((helm ls -n micro-onos | grep onos-umbrella) && helm del -n micro-onos onos-umbrella) || true

cleanup:
	sdcore-adapter-down
	aether-down

reset-test1:
	helm -n omec del oaisim || true
	rm -f /tmp/build/milestones/oaisim
