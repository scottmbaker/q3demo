# A collection of Makefile targets that are useful for interacting with the ROC

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
SDRAN_HELM_DIR=${ROOT_DIR}/sdran-helm-charts
ROC_HELM_DIR=${ROOT_DIR}/roc-helm-charts
#ROC_HELM_DIR=aether
K3D_SERVERS=1
K3D_AGENTS=0
AETHER_REST ?= ${ROOT_DIR}/demo-rest
AETHER_GNMI ?= ${ROOT_DIR}/demo-models
AETHER_ROC_API_URL ?= http://localhost:31190/aether-roc-api
SDCORE_TARGET ?= spgw-1
AETHER_VERSION ?= 1.0.0
REPO_USER ?= onfstaff
REPO_PASSWORD ?=
ATOMIX_CONTROLLER_VERSION?=0.6.8
ATOMIX_RAFT_VERSION=0.1.14
ONOS_OPERATOR_VERSION?=0.4.9

export AETHER_REST
export AETHER_GNMI
export AETHER_ROC_API_URL
export SDCORE_TARGET
export AETHER_VERSION
export ATOMIX_CONTROLLER_VERSION
export ATOMIX_RAFT_VERSION
export ONOS_OPERATOR_VERSION

${SDRAN_HELM_DIR}:
	git clone https://github.com/onosproject/sdran-helm-charts.git

docker-cred:
	kubectl -n micro-onos get secret regcred || kubectl --namespace micro-onos create secret docker-registry regcred --docker-username=${DOCKER_USERNAME} --docker-password=${DOCKER_PASSWORD} --docker-email=smbaker@gmail.com

bootstrap: ${SDRAN_HELM_DIR}
	helm repo add sdran --username ${REPO_USER} --password ${REPO_PASSWORD} https://sdrancharts.onosproject.org
	helm repo add atomix https://charts.atomix.io
	helm repo update
	cd ${SDRAN_HELM_DIR} && helm dep update aether-roc-umbrella

operator-up:
	#(kubectl -n kube-system get pods | grep onos-operator) || helm install -n kube-system onos-operator onosproject/onos-operator --version ${ONOS_OPERATOR_VERSION} --wait
	(kubectl -n kube-system get pods | grep onos-operator) || helm install -n kube-system onos-operator ~/projects/aether/onos-helm-charts/onos-operator --version ${ONOS_OPERATOR_VERSION} --wait


operator-down:
	helm -n kube-system del onos-operator

get-gnmi-models:
	rm -rf /tmp/config-models
	git clone --single-branch --branch feature/hss http://github.com/sbconsulting/config-models /tmp/config-models
	cp /tmp/config-models/modelplugin/aether-2.0.0/examples/*.gnmi demo-models/
	mkdir -p demo-models-v1
	cp /tmp/config-models/modelplugin/aether-1.0.0/examples/*.gnmi demo-models-v1/

k3d-cluster-up:
	k3d cluster list roc-devel || k3d cluster create roc-devel --servers ${K3D_SERVERS} --agents ${K3D_AGENTS} -p "31190:31190@server[0]" -p "31180:31180@server[0]" -p "8080:80@loadbalancer"

k3d-cluster-down:
	k3d cluster delete roc-devel

sdcore-adapter-topo:
	./scripts/waitforpod.sh micro-onos sdcore-adapter
	# This is now handled by the aether-roc-umbrella chart
	# ./scripts/occli topo add device ${SDCORE_TARGET} --address sdcore-adapter:5150 --role leaf --type Aether --version ${AETHER_VERSION}

sdcore-adapter-topo-v1:
	./scripts/occli topo add entity connectivity-service-v1 -k Aether -a address=sdcore-adapter-v1:5150 -a role=leaf -a version=1.0.0 -a tls-insecure=true -a grpcport=5150

aether-helm-update: ${SDRAN_HELM_DIR}
	cp aether-roc-umbrella-chart.yaml ${SDRAN_HELM_DIR}/aether-roc-umbrella/Chart.yaml
	cd ${SDRAN_HELM_DIR} && helm dep update aether-roc-umbrella

aether-namespace:
	kubectl get namespace micro-onos 2> /dev/null || kubectl create namespace micro-onos

aether-up: atomix-up operator-up aether-namespace docker-cred
	(helm ls -n micro-onos | grep aether-roc-umbrella) || helm -n micro-onos install aether-roc-umbrella ${ROC_HELM_DIR}/aether-roc-umbrella -f values-override.yaml
        # --set onos-config.openidc.issuer=https://dex.aetherproject.org/dex --set aether-roc-gui.openidc.issuer=https://dex.aetherproject.org/dex
	sleep 5
	kubectl wait pod -n micro-onos --for=condition=Ready -l type=config --timeout=300s
	#kubectl -n micro-onos apply -f sdran-helm-charts/aether-roc-umbrella/templates/topo.yaml

aether-upgrade:
	helm -n micro-onos upgrade aether-roc-umbrella ${SDRAN_HELM_DIR}/aether-roc-umbrella -f values-override.yaml

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

demo-post-%:
	scripts/load-directory.sh ${AETHER_ROC_API_URL}/aether/v$*/${SDCORE_TARGET}/ demo-rest-$*

fault-%:
	aether-post-internal $* faults/bad-$*.json

fix-%:
	aether-post-internal $* fix/fix-$*.json

post-production-%:
	scripts/load-directory.sh ${AETHER_ROC_API_URL}/aether/v$*/${SDCORE_TARGET}/ production-rest-$*

aether-down:
	kubectl -n micro-onos delete entity connectivity-service-v3 || true
	kubectl -n micro-onos delete entity connectivity-service-v2 || true
	kubectl -n micro-onos delete kind aether || true
	helm -n micro-onos delete $(shell helm -n micro-onos ls -q) || true
	scripts/waitfornotrunning.sh micro-onos
	scripts/waitforterm.sh micro-onos

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
	# create the micro-onos namespace here, leftover from when I used to install atomix to micro-onos
	kubectl get namespace micro-onos 2> /dev/null || kubectl create namespace micro-onos
	(helm ls -n kube-system | grep atomix-controller) || helm -n kube-system install atomix-controller atomix/atomix-controller --version ${ATOMIX_CONTROLLER_VERSION} --wait
	(helm ls -n kube-system | grep atomix-raft-storage) || helm -n kube-system install atomix-raft-storage atomix/atomix-raft-storage --version ${ATOMIX_RAFT_VERSION} --wait

install-go:
	curl -L https://golang.org/dl/go1.14.5.linux-amd64.tar.gz -o /tmp/go1.14.5.linux-amd64.tar.gz
	sudo tar -C /usr/local -xzf /tmp/go1.14.5.linux-amd64.tar.gz

install-ksniff:
	git clone https://github.com/eldadru/ksniff.git ~/ksniff
	cd ~/ksniff && PATH=$PATH:/usr/local/go/bin make linux 
	cd ~/ksniff && PATH=$PATH:/usr/local/go/bin make static-tcpdump
	cd ~/ksniff && sudo make install

unstuck:
	kubectl -n micro-onos patch entities connectivity-service-v2 --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' || true
	kubectl -n micro-onos patch entities connectivity-service-v3 --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' || true
	kubectl -n micro-onos patch kind aether --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]' || true

clean:
	rm -rf demo-models-v1/*.gnmi
	rm -rf demo-models/*.gnmi
