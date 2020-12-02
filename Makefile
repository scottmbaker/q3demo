# A collection of Makefile targets that are useful for interacting with the ROC

SDRAN_HELM_DIR=./sdran-helm-charts

${SDRAN_HELM_DIR}:
	git clone https://github.com/onosproject/sdran-helm-charts.git

bootstrap: ${SDRAN_HELM_DIR}
	cd ${SDRAN_HELM_DIR} && helm dep update aether-roc-umbrella

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
	./scripts/occli topo add device connectivity-service-v2 --address sdcore-adapter:5150 --role leaf --type Aether --version 2.0.0

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
	gnmiset set.apn-profile.gnmi
	gnmiset set.qos-profile.gnmi
	gnmiset set.up-profile.gnmi
	gnmiset set.subscriber.gnmi

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
	kubectl apply -f https://raw.githubusercontent.com/atomix/kubernetes-controller/master/deploy/atomix-controller.yaml
	kubectl apply -f https://raw.githubusercontent.com/atomix/raft-storage-controller/master/deploy/raft-storage-controller.yaml && kubectl apply -f https://raw.githubusercontent.com/atomix/cache-storage-controller/master/deploy/cache-storage-controller.yaml

install-go:
	curl -L https://golang.org/dl/go1.14.5.linux-amd64.tar.gz -o /tmp/go1.14.5.linux-amd64.tar.gz
	sudo tar -C /usr/local -xzf /tmp/go1.14.5.linux-amd64.tar.gz

install-ksniff:
	git clone https://github.com/eldadru/ksniff.git ~/ksniff
	cd ~/ksniff && PATH=$PATH:/usr/local/go/bin make linux 
	cd ~/ksniff && PATH=$PATH:/usr/local/go/bin make static-tcpdump
	cd ~/ksniff && sudo make install
