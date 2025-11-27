include ../../../.env
export

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
		-backend-config="storage_account_name=${AZURE_STORAGE_ACCOUNT_NAME}" \
		-backend-config="container_name=${AZURE_CONTAINER_NAME}" \
		-backend-config="resource_group_name=${AZURE_STATE_RESOURCE_GROUP}"

plan: lint
	terraform plan -input=false -out=tfplan

apply:
	terraform apply -input=false tfplan

destroy: empty-acr lint
	terraform destroy -auto-approve
