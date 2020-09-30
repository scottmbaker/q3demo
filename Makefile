SDRAN_HELM_DIR=./sdran-helm-charts

download-scripts:
	rm -rf /tmp/scott-misc
	git clone http://github.com/sbconsulting/misc /tmp/scott-misc
	sudo cp /tmp/scott-misc/aether-scripts/* /usr/bin

download-charts:
	git clone https://github.com/onosproject/sdran-helm-charts.git

sdcore-adapter-up:
	(helm ls -n micro-onos | grep sdcore-adapter) || helm install -n micro-onos sdcore-adapter ${SDRAN_HELM_DIR}/sdcore-adapter -f sdcore-adapter-override.yaml

sdcore-adapter-down:
	((helm ls -n micro-onos | grep sdcore-adapter) && helm del -n micro-onos sdcore-adapter) || true

sdcore-adapter-topo:
	./waitforpod.sh micro-onos sdcore-adapter
	occli topo add device spgw-1 --address sdcore-adapter:5150 --role leaf --type Aether --version 1.0.0
	#occli topo add device spgw-1 --address aether-roc-umbrella-sdcore-adapter:5150 --role leaf --type Aether --version 1.0.0

sdcore-adapter-reinstall: sdcore-adapter-down sdcore-adapter-up

aether-helm-update:
	cp aether-roc-umbrella-chart.yaml ${SDRAN_HELM_DIR}/aether-roc-umbrella/Chart.yaml
	cd ${SDRAN_HELM_DIR} && helm dep update aether-roc-umbrella

aether-up:
	kubectl get namespace micro-onos 2> /dev/null || kubectl create namespace micro-onos
	(helm ls -n micro-onos | grep aether-roc-umbrella) || helm -n micro-onos install aether-roc-umbrella ${SDRAN_HELM_DIR}/aether-roc-umbrella -f values-override.yaml
#	(helm ls -n micro-onos | grep onos-umbrella) || helm -n micro-onos install onos-umbrella onosproject/onos-umbrella -f values-override.yaml

aether-down:
	((helm ls -n micro-onos | grep aether-roc-umbrella) && helm del -n micro-onos aether-roc-umbrella) || true
#	((helm ls -n micro-onos | grep onos-umbrella) && helm del -n micro-onos onos-umbrella) || true

demo-up: aether-up sdcore-adapter-up sdcore-adapter-topo

demo-down: aether-down sdcore-adapter-down

demo-gnmi:
	gnmiset set.access-profile.gnmi
	sleep 2s
	gnmiset set.apn-profile.gnmi
	sleep 2s
	gnmiset set.qos-profile.gnmi
	sleep 2s
	gnmiset set.up-profile.gnmi
	sleep 2s
	gnmiset set.subscriber.gnmi

demo-post:
	aether-post access-profile access-profile.json
	sleep 2s
	aether-post apn-profile apn-profile.json
	sleep 2s
	aether-post qos-profile qos-profile.json
	sleep 2s
	aether-post up-profile up-profile.json
	sleep 2s
	aether-post up-profile up-profile-wrong.json
	sleep 2s
	aether-post subscriber subscriber.json

demo-wrong-up:
	aether-post subscriber subscriber-wrong-up.json

demo-right-up:
	aether-post subscriber subscriber.json

cleanup:
	sdcore-adapter-down
	aether-down

sdcore-down:
	cd ~/aether-in-a-box && make reset-test

sdcore-up:
	cd ~/aether-in-a-box && make /tmp/build/milestones/omec

sdcore-test:
	./waitforterm.sh omec
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
	helm repo add onosproject https://charts.onosproject.org
	helm repo update
	kubectl create -f https://raw.githubusercontent.com/atomix/kubernetes-controller/master/deploy/atomix-controller.yaml
	kubectl create -f https://raw.githubusercontent.com/atomix/raft-storage-controller/master/deploy/raft-storage-controller.yaml && kubectl create -f https://raw.githubusercontent.com/atomix/cache-storage-controller/master/deploy/cache-storage-controller.yaml

install-go:
	curl -L https://golang.org/dl/go1.14.5.linux-amd64.tar.gz -o /tmp/go1.14.5.linux-amd64.tar.gz
	sudo tar -C /usr/local -xzf /tmp/go1.14.5.linux-amd64.tar.gz

install-ksniff:
	git clone https://github.com/eldadru/ksniff.git ~/ksniff
	cd ~/ksniff && PATH=$PATH:/usr/local/go/bin make linux 
	cd ~/ksniff && PATH=$PATH:/usr/local/go/bin make static-tcpdump
	cd ~/ksniff && sudo make install
