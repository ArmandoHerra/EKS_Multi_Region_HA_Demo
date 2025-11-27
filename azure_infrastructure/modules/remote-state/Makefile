#!/bin/bash -x

include ../../.env
export

###### Terraform ######

lint:
	terraform fmt -recursive && terraform validate

clean:
	rm -rf .terraform && rm -f tfplan

init:
	terraform init -input=false

plan:
	make lint && terraform plan -input=false \
		-var="storage_account_name=${STORAGE_ACCOUNT_NAME}" \
		-var="resource_group_name=${STATE_RESOURCE_GROUP}" \
		-var="container_name=${CONTAINER_NAME}" \
		-out=tfplan

apply:
	terraform apply -input=false tfplan

# One-shot command: init, plan, and apply
bootstrap:
	make init && make plan && make apply

destroy:
	make lint && terraform destroy \
		-var="storage_account_name=${STORAGE_ACCOUNT_NAME}" \
		-var="resource_group_name=${STATE_RESOURCE_GROUP}" \
		-var="container_name=${CONTAINER_NAME}" \
		-auto-approve

# Show outputs after apply
outputs:
	terraform output
