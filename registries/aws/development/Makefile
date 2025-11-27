include ../../../.env
export

ECR_REPO_NAME ?= basic-demo-microservice-01

###### ECR ######

empty-ecr:
	./empty-ecr.sh $(ECR_REPO_NAME) east && \
	./empty-ecr.sh $(ECR_REPO_NAME) west

###### Terraform ######

lint:
	terraform fmt -recursive && terraform validate

clean:
	rm -rf .terraform && rm -f tfplan

init:
	terraform init -input=false \
	-backend-config="bucket=${AWS_REMOTE_BUCKET_NAME}" \
	-backend-config="dynamodb_table=${AWS_REMOTE_DYNAMODB_TABLE}"

plan: lint
	terraform plan \
	-var "remote_state_bucket=${AWS_REMOTE_BUCKET_NAME}" \
	-input=false -out=tfplan

apply:
	terraform apply -input=false tfplan

destroy: empty-ecr lint
	terraform destroy \
	-var "remote_state_bucket=${AWS_REMOTE_BUCKET_NAME}" \
	-auto-approve
