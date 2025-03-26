#!/bin/bash -x

include ../../.env
export 

###

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

empty-ecr:
	./empty-ecr.sh basic-demo-microservice-01 east && \
	./empty-ecr.sh basic-demo-microservice-01 west

destroy:
	make lint && \
	./empty-ecr.sh basic-demo-microservice-01 east && \
	./empty-ecr.sh basic-demo-microservice-01 west && \
	terraform destroy \
	-var "remote_state_bucket=${REMOTE_BUCKET_NAME}" \
	-auto-approve \
	-state=tfplan