#!/bin/bash -x

include ../../../.env
export

# Define variables for your clusters and AWS account.
CLUSTER_EAST_NAME ?= $(AWS_CLUSTER_EAST)
CLUSTER_WEST_NAME ?= $(AWS_CLUSTER_WEST)
REGION_EAST ?= us-east-1
REGION_WEST ?= us-west-2

###### Terraform ######

lint: 
	terraform fmt -recursive && terraform validate

clean:
	rm -rf .terraform && rm tfplan

init:
	terraform init -input=false \
	-backend-config="bucket=${AWS_REMOTE_BUCKET_NAME}" \
	-backend-config="dynamodb_table=${AWS_REMOTE_DYNAMODB_TABLE}"

refresh:
	make lint && \
	terraform refresh \
	-var "remote_state_bucket=${AWS_REMOTE_BUCKET_NAME}" \
	-var "ecr_repo_arn=${AWS_ECR_REPO_ARN}" \
	-input=false

plan:
	make lint && \
	terraform plan \
	-var "remote_state_bucket=${AWS_REMOTE_BUCKET_NAME}" \
	-var "ecr_repo_arn=${AWS_ECR_REPO_ARN}" \
	-input=false \
	-out=tfplan

apply:
	terraform apply -input=false tfplan

destroy:
	make lint && \
	terraform destroy \
	-var "remote_state_bucket=${AWS_REMOTE_BUCKET_NAME}" \
	-var "ecr_repo_arn=${AWS_ECR_REPO_ARN}" \
	-auto-approve

###### KubeConfig ######
.PHONY: kubeconfig-east kubeconfig-west use-east use-west

# Update kubeconfig for the east cluster
kubeconfig-east:
	@echo "Updating kubeconfig for ${CLUSTER_EAST_NAME} in ${REGION_EAST}..."
	aws eks update-kubeconfig --region $(REGION_EAST) --name $(CLUSTER_EAST_NAME)

# Update kubeconfig for the west cluster
kubeconfig-west:
	@echo "Updating kubeconfig for ${CLUSTER_WEST_NAME} in ${REGION_WEST}..."
	aws eks update-kubeconfig --region $(REGION_WEST) --name $(CLUSTER_WEST_NAME)

# Switch context to the east cluster
use-east:
	@echo "Switching context to ${CLUSTER_EAST_NAME}..."
	make kubeconfig-east && \
	kubectl config use-context arn:aws:eks:$(REGION_EAST):$(AWS_ACCOUNT_ID):cluster/$(CLUSTER_EAST_NAME)

# Switch context to the west cluster
use-west:
	@echo "Switching context to ${CLUSTER_WEST_NAME}..."
	make kubeconfig-west && \
	kubectl config use-context arn:aws:eks:$(REGION_WEST):$(AWS_ACCOUNT_ID):cluster/$(CLUSTER_WEST_NAME)

###### K8s App Deployment ######
.PHONY: deploy-nodereader-sa deploy-app deploy-debug 

# Deploy Node Reader Service Account
deploy-nodereader-sa:
	kubectl apply -f k8s/node-reader-sa.yaml

# Deploy Demo K8s Application
deploy-app:
	make deploy-nodereader-sa && \
	kubectl apply -f k8s/app.yaml

# Deploy Application for Debugging
deploy-debug:
	make deploy-nodereader-sa && \
	kubectl apply -f k8s/debug.yaml

###### Curl K8s Service ######

ping-service:
	@curl -k http://$$(kubectl get svc basic-demo-microservice-01-service \
	    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

ping-dns-record:
	curl -k http://eks-demo.armandoherra.games