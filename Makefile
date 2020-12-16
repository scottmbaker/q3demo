# A collection of Makefile targets that are useful for interacting with the ROC

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
SDRAN_HELM_DIR=${ROOT_DIR}/sdran-helm-charts
K3D_SERVERS=1
K3D_AGENTS=0
AETHER_REST ?= ${ROOT_DIR}/demo-rest
AETHER_GNMI ?= ${ROOT_DIR}/demo-models
AETHER_ROC_API_URL ?= http://localhost:31190/aether-roc-api
SDCORE_TARGET ?= spgw-1
AETHER_VERSION ?= 1.0.0
REPO_USER ?= onfstaff
REPO_PASSWORD ?=

export AETHER_REST
export AETHER_GNMI
export AETHER_ROC_API_URL
export SDCORE_TARGET
export AETHER_VERSION

${SDRAN_HELM_DIR}:
	git clone https://github.com/onosproject/sdran-helm-charts.git

bootstrap: ${SDRAN_HELM_DIR}
	helm repo add sdran --username ${REPO_USER} --password ${REPO_PASSWORD} https://sdrancharts.onosproject.org
	helm repo add atomix https://charts.atomix.io
	helm repo update
	cd ${SDRAN_HELM_DIR} && helm dep update aether-roc-umbrella

k3d-cluster-up:
	k3d cluster list roc-devel || k3d cluster create roc-devel --servers ${K3D_SERVERS} --agents ${K3D_AGENTS} -p "31190:31190@server[0]" -p "31180:31180@server[0]" -p "8080:80@loadbalancer"

k3d-cluster-down:
	k3d cluster delete roc-devel

sdcore-adapter-up:
	(helm ls -n micro-onos | grep sdcore-adapter) || helm install -n micro-onos sdcore-adapter ${SDRAN_HELM_DIR}/sdcore-adapter -f sdcore-adapter-override.yaml

sdcore-adapter-down:
	((helm ls -n micro-onos | grep sdcore-adapter) && helm del -n micro-onos sdcore-adapter) || true

sdcore-adapter-topo:
	./scripts/waitforpod.sh micro-onos sdcore-adapter
	./scripts/occli topo add device ${SDCORE_TARGET} --address sdcore-adapter:5150 --role leaf --type Aether --version ${AETHER_VERSION}

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

demo-gnmi:
	gnmiset set.access-profile.gnmi
	#sleep 2s
	gnmiset set.apn-profile.gnmi
	#sleep 2s
	gnmiset set.qos-profile.gnmi
	#sleep 2s
	gnmiset set.up-profile.gnmi
	#sleep 2s
	gnmiset set.subscriber.gnmi

demo-post:
	${ROOT_DIR}/scripts/aether-post access-profile access-profile.json
	sleep 2s
	${ROOT_DIR}/scripts/aether-post apn-profile apn-profile.json
	sleep 2s
	${ROOT_DIR}/scripts/aether-post qos-profile qos-profile.json
	sleep 2s
	${ROOT_DIR}/scripts/aether-post up-profile up-profile.json
	sleep 2s
	${ROOT_DIR}/scripts/aether-post up-profile up-profile-wrong.json
	sleep 2s
	${ROOT_DIR}/scripts/aether-post subscriber subscriber.json

# Put subscriber_mapping.json in the AETHER_REST directory and
# then run this.
# Example: make state-bootstrap AETHER_REST=./staging
state-bootstrap:
	cd ${AETHER_REST}; cat ./subscriber_mapping.json | ${ROOT_DIR}/scripts/read-spgw-configs.py
	${ROOT_DIR}/scripts/aether-post access-profile access-profiles.json
	sleep 2s
	${ROOT_DIR}/scripts/aether-post apn-profile apn-profiles.json
	sleep 2s
	${ROOT_DIR}/scripts/aether-post qos-profile qos-profiles.json
	sleep 2s
	${ROOT_DIR}/scripts/aether-post up-profile user-plane-profiles.json
	sleep 2s
	${ROOT_DIR}/scripts/aether-post subscriber subscribers.json

demo-wrong-up:
	${ROOT_DIR}/scripts/aether-post subscriber subscriber-wrong-up.json

demo-right-up:
	${ROOT_DIR}/scripts/aether-post subscriber subscriber-right-up.json

demo-disable:
	${ROOT_DIR}/scripts/aether-post subscriber subscriber-disabled.json

demo-enable:
	${ROOT_DIR}/scripts/aether-post subscriber subscriber-enabled.json

cleanup:
	helm -n micro-onos delete $(shell helm -n micro-onos ls -q)

sdcore-down:
	cd ~/aether-in-a-box && make reset-test

sdcore-up:
	cd ~/aether-in-a-box && make /tmp/build/milestones/omec

sdcore-test:
	${ROOT_DIR}/scripts/waitforterm.sh omec
	cd ~/aether-in-a-box && make test

sdcore-post:
	sdcore-post ${ROOT_DIR}/sdcore-sample-json/sample.json

sdcore-empty:
	sdcore-post ${ROOT_DIR}/sdcore-sample-json/empty.json

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
