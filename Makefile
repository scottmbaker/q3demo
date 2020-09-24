SDRAN_HELM_DIR=/users/smbaker/cord/sdran-helm-charts

sdcore-adapter-up:
	(helm ls -n micro-onos | grep sdcore-adapter) || helm install -n micro-onos sdcore-adapter ${SDRAN_HELM_DIR}/sdcore-adapter -f sdcore-adapter-override.yaml

sdcore-adapter-down:
	helm del -n micro-onos sdcore-adapter
