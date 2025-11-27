#!/bin/bash -x

include ../../../.env
export

# Define variables for your clusters
CLUSTER_EAST_NAME ?= $(AZURE_CLUSTER_EAST)
CLUSTER_WEST_NAME ?= $(AZURE_CLUSTER_WEST)
RG_EAST ?= $(AZURE_RG_EAST)
RG_WEST ?= $(AZURE_RG_WEST)

###### Terraform ######

lint:
	terraform fmt -recursive && terraform validate

clean:
	rm -rf .terraform && rm -f tfplan

init:
	terraform init -input=false \
		-backend-config="storage_account_name=${AZURE_STORAGE_ACCOUNT_NAME}" \
		-backend-config="container_name=${AZURE_CONTAINER_NAME}" \
		-backend-config="resource_group_name=${AZURE_STATE_RESOURCE_GROUP}"

refresh:
	make lint && \
	terraform refresh \
	-var "acr_registry_id=${AZURE_ACR_REGISTRY_ID}" \
	-input=false

plan:
	make lint && \
	terraform plan \
	-var "acr_registry_id=${AZURE_ACR_REGISTRY_ID}" \
	-input=false -out=tfplan

apply:
	terraform apply -input=false tfplan

destroy:
	make lint && \
	terraform destroy \
	-var "acr_registry_id=${AZURE_ACR_REGISTRY_ID}" \
	-auto-approve

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
