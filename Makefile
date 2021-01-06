# A collection of Makefile targets that are useful for interacting with the ROC

include ./scripts/env.sh

SDRAN_HELM_DIR=./sdran-helm-charts

${SDRAN_HELM_DIR}:
	git clone https://github.com/onosproject/sdran-helm-charts.git

bootstrap: ${SDRAN_HELM_DIR}
	cd ${SDRAN_HELM_DIR} && helm dep update aether-roc-umbrella
	helm repo add atomix https://charts.atomix.io
	helm repo update

get-gnmi-models:
	rm -rf /tmp/config-models
	git clone --single-branch --branch feature/hss http://github.com/sbconsulting/config-models /tmp/config-models
	cp /tmp/config-models/modelplugin/aether-2.0.0/examples/*.gnmi demo-models/
	mkdir -p demo-models-v1
	cp /tmp/config-models/modelplugin/aether-1.0.0/examples/*.gnmi demo-models-v1/

k3d-cluster-up:
	k3d cluster list roc-devel || k3d cluster create roc-devel -p "31190:31190@server[0]" -p "31180:31180@server[0]" -p "8080:80@loadbalancer"

k3d-cluster-down:
	k3d cluster delete roc-devel

sdcore-adapter-up:
	(helm ls -n micro-onos | grep sdcore-adapter) || helm install -n micro-onos sdcore-adapter ${SDRAN_HELM_DIR}/sdcore-adapter -f sdcore-adapter-override.yaml

sdcore-adapter-down:
	((helm ls -n micro-onos | grep sdcore-adapter) && helm del -n micro-onos sdcore-adapter) || true

sdcore-adapter-topo:
	./scripts/waitforpod.sh micro-onos sdcore-adapter
	# This is now handled by the aether-roc-umbrella chart
	# ./scripts/occli topo add device ${SDCORE_TARGET} --address sdcore-adapter:5150 --role leaf --type Aether --version ${AETHER_VERSION}

sdcore-adapter-topo-v1:
	./scripts/occli topo add entity connectivity-service-v1 -k Aether -a address=sdcore-adapter-v1:5150 -a role=leaf -a version=1.0.0 -a tls-insecure=true -a grpcport=5150

sdcore-adapter-reinstall: sdcore-adapter-down sdcore-adapter-up

aether-helm-update: ${SDRAN_HELM_DIR}
	cp aether-roc-umbrella-chart.yaml ${SDRAN_HELM_DIR}/aether-roc-umbrella/Chart.yaml
	cd ${SDRAN_HELM_DIR} && helm dep update aether-roc-umbrella

aether-up: atomix-up
	kubectl get namespace micro-onos 2> /dev/null || kubectl create namespace micro-onos
	(helm ls -n micro-onos | grep aether-roc-umbrella) || helm -n micro-onos install aether-roc-umbrella ${SDRAN_HELM_DIR}/aether-roc-umbrella -f values-override.yaml

aether-down:
	((helm ls -n micro-onos | grep aether-roc-umbrella) && helm del -n micro-onos aether-roc-umbrella) || true

demo-up: aether-up sdcore-adapter-up sdcore-adapter-topo

demo-down: aether-down sdcore-adapter-down

demo-gnmi: demo-gnmi-v2

demo-gnmi-v2:
	gnmiset set.connectivity-service-aib.gnmi
	gnmiset set.enterprise.gnmi
	gnmiset set.access-profile.gnmi
	gnmiset set.apn-profile.gnmi
	gnmiset set.qos-profile.gnmi
	gnmiset set.up-profile.gnmi
	gnmiset set.security-profile.gnmi
	gnmiset set.subscriber-aib.gnmi

demo-gnmi-v1:
	gnmiset demo-models-v1/set.access-profile.gnmi
	gnmiset demo-models-v1/set.apn-profile.gnmi
	gnmiset demo-models-v1/set.qos-profile.gnmi
	gnmiset demo-models-v1/set.up-profile.gnmi
	gnmiset demo-models-v1/set.subscriber.gnmi

demo-post:
	./scripts/aether-post access-profile access-profile.json
	sleep 2s
	./scripts/aether-post apn-profile apn-profile.json
	sleep 2s
	./scripts/aether-post qos-profile qos-profile.json
	sleep 2s
	./scripts/aether-post up-profile up-profile.json
	sleep 2s
	./scripts/aether-post up-profile up-profile-wrong.json
	sleep 2s
	./scripts/aether-post subscriber subscriber.json

demo-wrong-up:
	./scripts/aether-post subscriber subscriber-wrong-up.json

demo-right-up:
	./scripts/aether-post subscriber subscriber-right-up.json

demo-disable:
	./scripts/aether-post subscriber subscriber-disabled.json

demo-enable:
	./scripts/aether-post subscriber subscriber-enabled.json

cleanup: sdcore-adapter-down aether-down

sdcore-down:
	cd ~/aether-in-a-box && make reset-test

sdcore-up:
	cd ~/aether-in-a-box && make /tmp/build/milestones/omec

sdcore-test:
	./scripts/waitforterm.sh omec
	cd ~/aether-in-a-box && make test

sdcore-post:
	sdcore-post ./sdcore-sample-json/sample.json

sdcore-empty:
	sdcore-post ./sdcore-sample-json/empty.json

sdcore-retest: sdcore-reset-oaisim sdcore-test

sdcore-reset-oaisim:
	helm -n omec del oaisim || true
	rm -f /tmp/build/milestones/oaisim

atomix-up:
	kubectl get namespace micro-onos 2> /dev/null || kubectl create namespace micro-onos
	(helm ls -n micro-onos | grep atomix-controller) || helm -n micro-onos install atomix-controller atomix/atomix-controller --set scope=Namespace
	(helm ls -n micro-onos | grep raft-storage-controller) || helm -n micro-onos install raft-storage-controller atomix/raft-storage-controller --set scope=Namespace

install-go:
	curl -L https://golang.org/dl/go1.14.5.linux-amd64.tar.gz -o /tmp/go1.14.5.linux-amd64.tar.gz
	sudo tar -C /usr/local -xzf /tmp/go1.14.5.linux-amd64.tar.gz

install-ksniff:
	git clone https://github.com/eldadru/ksniff.git ~/ksniff
	cd ~/ksniff && PATH=$PATH:/usr/local/go/bin make linux 
	cd ~/ksniff && PATH=$PATH:/usr/local/go/bin make static-tcpdump
	cd ~/ksniff && sudo make install

clean:
	rm -rf demo-models-v1/*.gnmi
	rm -rf demo-models/*.gnmi
