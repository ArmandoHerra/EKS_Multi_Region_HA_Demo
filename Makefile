include .env
export

# Directory paths
AWS_EKS_DIR := aws_infrastructure/environments/development
AZURE_AKS_DIR := azure_infrastructure/environments/development
AWS_ECR_DIR := registries/aws/development
AZURE_ACR_DIR := registries/azure/development

.PHONY: help init plan apply destroy \
        init-registries plan-registries apply-registries destroy-registries \
        init-clusters plan-clusters apply-clusters destroy-clusters \
        failover revert \
        use-aws-east use-aws-west use-azure-east use-azure-west \
        deploy-app-aws-east deploy-app-aws-west deploy-app-azure-east deploy-app-azure-west deploy-app-all \
        validate-traffic

help:
	@echo "Multi-Cloud Infrastructure Commands:"
	@echo ""
	@echo "  Registry Commands (ECR + ACR):"
	@echo "    make init-registries     Initialize both ECR and ACR (parallel)"
	@echo "    make plan-registries     Plan both ECR and ACR (parallel)"
	@echo "    make apply-registries    Apply both ECR and ACR (parallel)"
	@echo "    make destroy-registries  Destroy both ECR and ACR (parallel)"
	@echo ""
	@echo "  Cluster Commands (EKS + AKS):"
	@echo "    make init-clusters       Initialize both EKS and AKS (parallel)"
	@echo "    make plan-clusters       Plan both EKS and AKS (parallel)"
	@echo "    make apply-clusters      Apply both EKS and AKS (parallel)"
	@echo "    make destroy-clusters    Destroy both EKS and AKS (parallel)"
	@echo ""
	@echo "  Full Stack Commands:"
	@echo "    make init                Initialize all (registries, then clusters)"
	@echo "    make plan                Plan all (registries, then clusters)"
	@echo "    make apply               Apply all (registries, then clusters)"
	@echo "    make destroy             Destroy all (clusters first, then registries)"
	@echo ""
	@echo "  Failover Testing:"
	@echo "    make failover            Scale AWS deployments to 0 (simulate failure)"
	@echo "    make revert              Scale AWS deployments back to 3"
	@echo ""
	@echo "  Kubectl Context Switching:"
	@echo "    make use-aws-east        Switch to EKS East (us-east-1)"
	@echo "    make use-aws-west        Switch to EKS West (us-west-2)"
	@echo "    make use-azure-east      Switch to AKS East (eastus)"
	@echo "    make use-azure-west      Switch to AKS West (westus2)"
	@echo ""
	@echo "  App Deployment:"
	@echo "    make deploy-app-aws-east    Deploy app to EKS East"
	@echo "    make deploy-app-aws-west    Deploy app to EKS West"
	@echo "    make deploy-app-azure-east  Deploy app to AKS East"
	@echo "    make deploy-app-azure-west  Deploy app to AKS West"
	@echo "    make deploy-app-all         Deploy app to all 4 clusters (parallel)"
	@echo ""
	@echo "  Traffic Validation:"
	@echo "    make validate-traffic       Validate DNS records and health of all regions"

# =============================================================================
# Registry Commands - Run in Parallel
# =============================================================================

init-registries:
	@echo "=== Initializing Registries (ECR + ACR) ==="
	$(MAKE) -C $(AWS_ECR_DIR) init & \
	$(MAKE) -C $(AZURE_ACR_DIR) init & \
	wait

plan-registries:
	@echo "=== Planning Registries (ECR + ACR) ==="
	$(MAKE) -C $(AWS_ECR_DIR) plan & \
	$(MAKE) -C $(AZURE_ACR_DIR) plan & \
	wait

apply-registries:
	@echo "=== Applying Registries (ECR + ACR) ==="
	$(MAKE) -C $(AWS_ECR_DIR) apply & \
	$(MAKE) -C $(AZURE_ACR_DIR) apply & \
	wait

destroy-registries:
	@echo "=== Destroying Registries (ECR + ACR) ==="
	$(MAKE) -C $(AWS_ECR_DIR) destroy & \
	$(MAKE) -C $(AZURE_ACR_DIR) destroy & \
	wait

# =============================================================================
# Cluster Commands - Run in Parallel
# =============================================================================

init-clusters:
	@echo "=== Initializing Clusters (EKS + AKS) ==="
	$(MAKE) -C $(AWS_EKS_DIR) init & \
	$(MAKE) -C $(AZURE_AKS_DIR) init & \
	wait

plan-clusters:
	@echo "=== Planning Clusters (EKS + AKS) ==="
	$(MAKE) -C $(AWS_EKS_DIR) plan & \
	$(MAKE) -C $(AZURE_AKS_DIR) plan & \
	wait

apply-clusters:
	@echo "=== Applying Clusters (EKS + AKS) ==="
	$(MAKE) -C $(AWS_EKS_DIR) apply & \
	$(MAKE) -C $(AZURE_AKS_DIR) apply & \
	wait

destroy-clusters:
	@echo "=== Destroying Clusters (EKS + AKS) ==="
	$(MAKE) -C $(AWS_EKS_DIR) destroy & \
	$(MAKE) -C $(AZURE_AKS_DIR) destroy & \
	wait

# =============================================================================
# Full Stack Commands (Sequential: Registries first, then Clusters)
# =============================================================================

init: init-registries init-clusters

plan: plan-registries plan-clusters

apply: apply-registries apply-clusters

destroy: destroy-clusters destroy-registries

# =============================================================================
# Failover Testing Commands
# =============================================================================

failover:
	@echo "=== Simulating AWS Failure: Scaling deployments to 0 ==="
	@echo "Switching to EKS East..."
	@aws eks update-kubeconfig --region us-east-1 --name $(AWS_CLUSTER_EAST) 2>/dev/null
	@kubectl scale deployment $(K8S_DEPLOYMENT_NAME) --replicas=0
	@echo "Switching to EKS West..."
	@aws eks update-kubeconfig --region us-west-2 --name $(AWS_CLUSTER_WEST) 2>/dev/null
	@kubectl scale deployment $(K8S_DEPLOYMENT_NAME) --replicas=0
	@echo ""
	@echo "=== AWS deployments scaled to 0 ==="
	@echo "Route53 will detect failure in ~90 seconds (3 checks * 30s interval)"
	@echo "Traffic will failover to Azure."

revert:
	@echo "=== Reverting: Scaling AWS deployments back to $(K8S_REPLICAS) ==="
	@echo "Switching to EKS East..."
	@aws eks update-kubeconfig --region us-east-1 --name $(AWS_CLUSTER_EAST) 2>/dev/null
	@kubectl scale deployment $(K8S_DEPLOYMENT_NAME) --replicas=$(K8S_REPLICAS)
	@echo "Switching to EKS West..."
	@aws eks update-kubeconfig --region us-west-2 --name $(AWS_CLUSTER_WEST) 2>/dev/null
	@kubectl scale deployment $(K8S_DEPLOYMENT_NAME) --replicas=$(K8S_REPLICAS)
	@echo ""
	@echo "=== AWS deployments restored ==="
	@echo "Route53 will restore AWS as primary after health checks pass (~30-60s)."

# =============================================================================
# Kubectl Context Switching
# =============================================================================

use-aws-east:
	@echo "=== Switching to EKS East (us-east-1) ==="
	@aws eks update-kubeconfig --region us-east-1 --name $(AWS_CLUSTER_EAST)
	@kubectl config use-context arn:aws:eks:us-east-1:$(AWS_ACCOUNT_ID):cluster/$(AWS_CLUSTER_EAST)

use-aws-west:
	@echo "=== Switching to EKS West (us-west-2) ==="
	@aws eks update-kubeconfig --region us-west-2 --name $(AWS_CLUSTER_WEST)
	@kubectl config use-context arn:aws:eks:us-west-2:$(AWS_ACCOUNT_ID):cluster/$(AWS_CLUSTER_WEST)

use-azure-east:
	@echo "=== Switching to AKS East (eastus) ==="
	@az aks get-credentials --resource-group $(AZURE_RG_EAST) --name $(AZURE_CLUSTER_EAST) --overwrite-existing
	@kubectl config use-context $(AZURE_CLUSTER_EAST)

use-azure-west:
	@echo "=== Switching to AKS West (westus2) ==="
	@az aks get-credentials --resource-group $(AZURE_RG_WEST) --name $(AZURE_CLUSTER_WEST) --overwrite-existing
	@kubectl config use-context $(AZURE_CLUSTER_WEST)

# =============================================================================
# App Deployment Commands
# =============================================================================

deploy-app-aws-east: use-aws-east
	@echo "=== Deploying app to EKS East ==="
	$(MAKE) -C $(AWS_EKS_DIR) deploy-app

deploy-app-aws-west: use-aws-west
	@echo "=== Deploying app to EKS West ==="
	$(MAKE) -C $(AWS_EKS_DIR) deploy-app

deploy-app-azure-east: use-azure-east
	@echo "=== Deploying app to AKS East ==="
	$(MAKE) -C $(AZURE_AKS_DIR) deploy-app

deploy-app-azure-west: use-azure-west
	@echo "=== Deploying app to AKS West ==="
	$(MAKE) -C $(AZURE_AKS_DIR) deploy-app

deploy-app-all:
	@echo "=== Deploying app to all 4 clusters (sequential) ==="
	$(MAKE) deploy-app-aws-east
	$(MAKE) deploy-app-aws-west
	$(MAKE) deploy-app-azure-east
	$(MAKE) deploy-app-azure-west
	@echo "=== App deployed to all clusters ==="

# =============================================================================
# Traffic Validation
# =============================================================================

validate-traffic:
	@echo "============================================================================="
	@echo "                      TRAFFIC VALIDATION REPORT"
	@echo "============================================================================="
	@echo ""
	@echo "=== 1. DNS Resolution ==="
	@echo ""
	@echo "Main Record ($(SUBDOMAIN).$(DOMAIN_NAME)):"
	@dig +short $(SUBDOMAIN).$(DOMAIN_NAME) 2>/dev/null || echo "  [ERROR] DNS lookup failed"
	@echo ""
	@echo "AWS Pool ($(AWS_POOL_SUBDOMAIN).$(SUBDOMAIN).$(DOMAIN_NAME)):"
	@dig +short $(AWS_POOL_SUBDOMAIN).$(SUBDOMAIN).$(DOMAIN_NAME) 2>/dev/null || echo "  [ERROR] DNS lookup failed"
	@echo ""
	@echo "============================================================================="
	@echo "=== 2. Route53 Health Checks ==="
	@echo "============================================================================="
	@echo ""
	@aws route53 list-health-checks --query 'HealthChecks[*].[Id,HealthCheckConfig.FullyQualifiedDomainName,HealthCheckConfig.IPAddress]' --output text 2>/dev/null | while read id fqdn ip; do \
		if [ -n "$$id" ]; then \
			status=$$(aws route53 get-health-check-status --health-check-id $$id --query 'HealthCheckObservations[0].StatusReport.Status' --output text 2>/dev/null); \
			target="$$fqdn"; \
			[ -z "$$target" ] || [ "$$target" = "None" ] && target="$$ip"; \
			if echo "$$status" | grep -qi "success\|healthy"; then \
				echo "  [OK] $$target - $$status"; \
			else \
				echo "  [FAIL] $$target - $$status"; \
			fi; \
		fi; \
	done
	@echo ""
	@echo "============================================================================="
	@echo "=== 3. LoadBalancer Endpoints & Health ==="
	@echo "============================================================================="
	@echo ""
	@echo "--- AWS EKS East (us-east-1) ---"
	@aws eks update-kubeconfig --region us-east-1 --name $(AWS_CLUSTER_EAST) 2>/dev/null || true
	@AWS_EAST_LB=$$(kubectl get svc $(K8S_DEPLOYMENT_NAME)-service -n $(K8S_NAMESPACE) -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null); \
	if [ -n "$$AWS_EAST_LB" ]; then \
		echo "  Endpoint: $$AWS_EAST_LB"; \
		ELB_NAME=$$(echo $$AWS_EAST_LB | cut -d'-' -f1); \
		echo "  ELB Target Health:"; \
		aws elbv2 describe-target-groups --region us-east-1 --query "TargetGroups[?contains(TargetGroupName, '$$ELB_NAME')].TargetGroupArn" --output text 2>/dev/null | while read tg_arn; do \
			if [ -n "$$tg_arn" ]; then \
				aws elbv2 describe-target-health --region us-east-1 --target-group-arn $$tg_arn --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' --output text 2>/dev/null | while read target state; do \
					if [ "$$state" = "healthy" ]; then echo "    [OK] $$target: $$state"; else echo "    [FAIL] $$target: $$state"; fi; \
				done; \
			fi; \
		done; \
		echo "  HTTP Check:"; \
		HTTP_CODE=$$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 "http://$$AWS_EAST_LB" 2>/dev/null); \
		if [ "$$HTTP_CODE" = "200" ]; then echo "    [OK] HTTP $$HTTP_CODE"; else echo "    [FAIL] HTTP $$HTTP_CODE"; fi; \
	else \
		echo "  [SKIP] Service not deployed"; \
	fi
	@echo ""
	@echo "--- AWS EKS West (us-west-2) ---"
	@aws eks update-kubeconfig --region us-west-2 --name $(AWS_CLUSTER_WEST) 2>/dev/null || true
	@AWS_WEST_LB=$$(kubectl get svc $(K8S_DEPLOYMENT_NAME)-service -n $(K8S_NAMESPACE) -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null); \
	if [ -n "$$AWS_WEST_LB" ]; then \
		echo "  Endpoint: $$AWS_WEST_LB"; \
		ELB_NAME=$$(echo $$AWS_WEST_LB | cut -d'-' -f1); \
		echo "  ELB Target Health:"; \
		aws elbv2 describe-target-groups --region us-west-2 --query "TargetGroups[?contains(TargetGroupName, '$$ELB_NAME')].TargetGroupArn" --output text 2>/dev/null | while read tg_arn; do \
			if [ -n "$$tg_arn" ]; then \
				aws elbv2 describe-target-health --region us-west-2 --target-group-arn $$tg_arn --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' --output text 2>/dev/null | while read target state; do \
					if [ "$$state" = "healthy" ]; then echo "    [OK] $$target: $$state"; else echo "    [FAIL] $$target: $$state"; fi; \
				done; \
			fi; \
		done; \
		echo "  HTTP Check:"; \
		HTTP_CODE=$$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 "http://$$AWS_WEST_LB" 2>/dev/null); \
		if [ "$$HTTP_CODE" = "200" ]; then echo "    [OK] HTTP $$HTTP_CODE"; else echo "    [FAIL] HTTP $$HTTP_CODE"; fi; \
	else \
		echo "  [SKIP] Service not deployed"; \
	fi
	@echo ""
	@echo "--- Azure AKS East (eastus) ---"
	@az aks get-credentials --resource-group $(AZURE_RG_EAST) --name $(AZURE_CLUSTER_EAST) --overwrite-existing 2>/dev/null || true
	@AZURE_EAST_LB=$$(kubectl get svc $(K8S_DEPLOYMENT_NAME)-service -n $(K8S_NAMESPACE) -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null); \
	if [ -n "$$AZURE_EAST_LB" ]; then \
		echo "  Endpoint: $$AZURE_EAST_LB"; \
		echo "  Azure LB Backend Health:"; \
		az network lb list --resource-group MC_$(AZURE_RG_EAST)_$(AZURE_CLUSTER_EAST)_eastus --query "[].name" -o tsv 2>/dev/null | head -1 | while read lb_name; do \
			if [ -n "$$lb_name" ]; then \
				az network lb probe list --resource-group MC_$(AZURE_RG_EAST)_$(AZURE_CLUSTER_EAST)_eastus --lb-name $$lb_name --query "[].{name:name,protocol:protocol,port:port}" -o table 2>/dev/null | tail -n +3 | while read line; do \
					echo "    Probe: $$line"; \
				done; \
			fi; \
		done; \
		echo "  HTTP Check:"; \
		HTTP_CODE=$$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 "http://$$AZURE_EAST_LB" 2>/dev/null); \
		if [ "$$HTTP_CODE" = "200" ]; then echo "    [OK] HTTP $$HTTP_CODE"; else echo "    [FAIL] HTTP $$HTTP_CODE"; fi; \
	else \
		echo "  [SKIP] Service not deployed"; \
	fi
	@echo ""
	@echo "--- Azure AKS West (westus2) ---"
	@az aks get-credentials --resource-group $(AZURE_RG_WEST) --name $(AZURE_CLUSTER_WEST) --overwrite-existing 2>/dev/null || true
	@AZURE_WEST_LB=$$(kubectl get svc $(K8S_DEPLOYMENT_NAME)-service -n $(K8S_NAMESPACE) -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null); \
	if [ -n "$$AZURE_WEST_LB" ]; then \
		echo "  Endpoint: $$AZURE_WEST_LB"; \
		echo "  Azure LB Backend Health:"; \
		az network lb list --resource-group MC_$(AZURE_RG_WEST)_$(AZURE_CLUSTER_WEST)_westus2 --query "[].name" -o tsv 2>/dev/null | head -1 | while read lb_name; do \
			if [ -n "$$lb_name" ]; then \
				az network lb probe list --resource-group MC_$(AZURE_RG_WEST)_$(AZURE_CLUSTER_WEST)_westus2 --lb-name $$lb_name --query "[].{name:name,protocol:protocol,port:port}" -o table 2>/dev/null | tail -n +3 | while read line; do \
					echo "    Probe: $$line"; \
				done; \
			fi; \
		done; \
		echo "  HTTP Check:"; \
		HTTP_CODE=$$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 "http://$$AZURE_WEST_LB" 2>/dev/null); \
		if [ "$$HTTP_CODE" = "200" ]; then echo "    [OK] HTTP $$HTTP_CODE"; else echo "    [FAIL] HTTP $$HTTP_CODE"; fi; \
	else \
		echo "  [SKIP] Service not deployed"; \
	fi
	@echo ""
	@echo "============================================================================="
	@echo "=== 4. Main DNS Endpoint Health ==="
	@echo "============================================================================="
	@echo ""
	@echo "Testing $(SUBDOMAIN).$(DOMAIN_NAME):"
	@HTTP_CODE=$$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 "http://$(SUBDOMAIN).$(DOMAIN_NAME)" 2>/dev/null); \
	if [ "$$HTTP_CODE" = "200" ]; then \
		echo "  [OK] HTTP $$HTTP_CODE - Traffic routing is working"; \
	else \
		echo "  [FAIL] HTTP $$HTTP_CODE"; \
	fi
	@echo ""
	@echo "============================================================================="
	@echo "                      VALIDATION COMPLETE"
	@echo "============================================================================="
