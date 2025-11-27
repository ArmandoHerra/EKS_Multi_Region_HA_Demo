#!/bin/bash -x

include ../../.env
export

# Define variables for your clusters
CLUSTER_EAST_NAME ?= aks-cluster-dev-east
CLUSTER_WEST_NAME ?= aks-cluster-dev-west
RG_EAST ?= aks-multiregion-demo-dev-east-rg
RG_WEST ?= aks-multiregion-demo-dev-west-rg
ACR_NAME ?= aksmultiregiondemoacr

###### ACR ######

login-acr:
	az acr login --name $(ACR_NAME)

empty-acr:
	az acr repository delete --name $(ACR_NAME) --repository basic-demo-microservice-01 --yes || true

###### Terraform ######

lint:
	terraform fmt -recursive && terraform validate

clean:
	rm -rf .terraform && rm -f tfplan

init:
	terraform init -input=false \
		-backend-config="storage_account_name=${STORAGE_ACCOUNT_NAME}" \
		-backend-config="container_name=${CONTAINER_NAME}" \
		-backend-config="resource_group_name=${STATE_RESOURCE_GROUP}"

refresh:
	make lint && terraform refresh -input=false

plan:
	make lint && terraform plan -input=false -out=tfplan

apply:
	terraform apply -input=false tfplan

destroy:
	make lint && \
	make empty-acr && \
	terraform destroy -auto-approve

###### KubeConfig ######
.PHONY: kubeconfig-east kubeconfig-west use-east use-west

# Update kubeconfig for the east cluster
kubeconfig-east:
	@echo "Updating kubeconfig for $(CLUSTER_EAST_NAME) in East US..."
	az aks get-credentials --resource-group $(RG_EAST) --name $(CLUSTER_EAST_NAME) --overwrite-existing

# Update kubeconfig for the west cluster
kubeconfig-west:
	@echo "Updating kubeconfig for $(CLUSTER_WEST_NAME) in West US 2..."
	az aks get-credentials --resource-group $(RG_WEST) --name $(CLUSTER_WEST_NAME) --overwrite-existing

# Switch context to the east cluster
use-east:
	@echo "Switching context to $(CLUSTER_EAST_NAME)..."
	make kubeconfig-east && kubectl config use-context $(CLUSTER_EAST_NAME)

# Switch context to the west cluster
use-west:
	@echo "Switching context to $(CLUSTER_WEST_NAME)..."
	make kubeconfig-west && kubectl config use-context $(CLUSTER_WEST_NAME)

###### K8s App Deployment ######
.PHONY: deploy-nodereader-sa deploy-app

# Deploy Node Reader Service Account
deploy-nodereader-sa:
	kubectl apply -f k8s/node-reader-sa.yaml

# Deploy Demo K8s Application
deploy-app:
	make deploy-nodereader-sa && kubectl apply -f k8s/app.yaml

###### Curl K8s Service ######

ping-service:
	@curl -k http://$$(kubectl get svc basic-demo-microservice-01-service \
		-o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Get LoadBalancer IPs for Route 53 configuration
get-lb-ips:
	@echo "East US LoadBalancer IP:"
	@kubectl config use-context $(CLUSTER_EAST_NAME) 2>/dev/null && \
		kubectl get svc basic-demo-microservice-01-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' && echo
	@echo "West US 2 LoadBalancer IP:"
	@kubectl config use-context $(CLUSTER_WEST_NAME) 2>/dev/null && \
		kubectl get svc basic-demo-microservice-01-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' && echo
