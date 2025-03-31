#!/bin/bash -x

include ../../.env
export 

# Define variables for your clusters and AWS account.
AWS_ACCOUNT_ID ?= 933673765333
CLUSTER_EAST_NAME ?= eks-cluster-dev-east
CLUSTER_WEST_NAME ?= eks-cluster-dev-west
REGION_EAST ?= us-east-1
REGION_WEST ?= us-west-2


### ECR

empty-ecr:
	./empty-ecr.sh basic-demo-microservice-01 east && \
	./empty-ecr.sh basic-demo-microservice-01 west

### Terraform 

lint: 
	terraform fmt -recursive && terraform validate

clean:
	rm -rf .terraform && rm tfplan

init: 
	terraform init -input=false \
	-backend-config="bucket=${REMOTE_BUCKET_NAME}" \
	-backend-config="dynamodb_table=${REMOTE_DYNAMODB_TABLE}" && \
	export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

refresh:
	make lint && \
	terraform refresh \
	-var "remote_state_bucket=${REMOTE_BUCKET_NAME}" \
	-input=false

plan: 
	make lint && \
	terraform plan \
	-var "remote_state_bucket=${REMOTE_BUCKET_NAME}" \
	-input=false \
	-out=tfplan

apply:
	terraform apply -input=false tfplan

destroy:
	make lint && \
	./empty-ecr.sh basic-demo-microservice-01 east && \
	./empty-ecr.sh basic-demo-microservice-01 west && \
	terraform destroy \
	-var "remote_state_bucket=${REMOTE_BUCKET_NAME}" \
	-auto-approve \
	-state=tfplan

### KubeConfig

.PHONY: kubeconfig-east kubeconfig-west use-east use-west

# Update kubeconfig for the east cluster
kubeconfig-east:
	@echo "Updating kubeconfig for ${CLUSTER_EAST_NAME} in ${REGION_EAST}..."
	aws eks update-kubeconfig --region $(REGION_EAST) --name $(CLUSTER_EAST_NAME)

# Update kubeconfig for the west cluster
kubeconfig-west:
	@echo "Updating kubeconfig for ${CLUSTER_WEST_NAME} in ${REGION_WEST}..."
	aws eks update-kubeconfig --region $(REGION_WEST) --name $(CLUSTER_WEST_NAME)

# Switch context to the east cluster (you may need to adjust the context name format as output by update-kubeconfig)
use-east: kubeconfig-east
	@echo "Switching context to ${CLUSTER_EAST_NAME}..."
	kubectl config use-context arn:aws:eks:$(REGION_EAST):$(AWS_ACCOUNT_ID):cluster/$(CLUSTER_EAST_NAME)

# Switch context to the west cluster
use-west: kubeconfig-west
	@echo "Switching context to ${CLUSTER_WEST_NAME}..."
	kubectl config use-context arn:aws:eks:$(REGION_WEST):$(AWS_ACCOUNT_ID):cluster/$(CLUSTER_WEST_NAME)