# Multi-Cloud Multi-Region High Availability Demo

A demonstration of Multi-Cloud, Multi-Region High Availability architecture using Amazon EKS and Azure AKS, showcasing cross-region container registry replication, DNS-based failover with Route53, and optional cross-cloud failover between AWS and Azure.

## Architecture Overview

This project deploys a fully redundant infrastructure across two AWS regions with optional cross-cloud failover to Azure:

```
                              ┌─────────────────────┐
                              │   Route53 (DNS)     │
                              │  eks-demo.domain    │
                              │  FAILOVER ROUTING   │
                              └──────────┬──────────┘
                                         │
                    ┌────────────────────┴───────────────────┐
                    │                                        │
              ┌─────┴─────┐                            ┌─────┴─────┐
              │  PRIMARY  │                            │ SECONDARY │
              └─────┬─────┘                            └─────┬─────┘
                    │                                        │
                    ▼                                        ▼
       ┌────────────────────────┐                  ┌──────────────────┐
       │  aws-pool.eks-demo     │                  │   Azure Cloud    │
       │   WEIGHTED ROUTING     │                  │  (Standby)       │
       │      (50% / 50%)       │                  │                  │
       └───────────┬────────────┘                  │ eastus + westus2 │
                   │                               │  LoadBalancers   │
       ┌───────────┴───────────┐                   └──────────────────┘
       │                       │
       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   AWS Cloud     │    │   AWS Cloud     │
│   us-east-1     │    │   us-west-2     │
│                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │    ECR      │─┼────┼─│    ECR      │ │
│ │  (Primary)  │ │Repl│ │ (Replica)   │ │
│ └─────────────┘ │    │ └─────────────┘ │
│                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ EKS Cluster │ │    │ │ EKS Cluster │ │
│ │  (3 nodes)  │ │    │ │  (3 nodes)  │ │
│ │ Demo App x3 │ │    │ │ Demo App x3 │ │
│ │LoadBalancer │ │    │ │LoadBalancer │ │
│ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘
          │                    │
          └────────┬───────────┘
                   ▼
        ┌─────────────────────┐
        │   GitHub Actions    │
        │    (OIDC Auth)      │
        └─────────────────────┘
```

### Key Components

| Component | Description |
|-----------|-------------|
| **ECR Repositories** | Container registries in both AWS regions with automatic cross-region replication |
| **EKS Clusters** | Kubernetes 1.34 clusters with managed node groups (3-6 nodes each) |
| **Route53** | Nested routing: weighted AWS pool (50/50 East/West) as PRIMARY, Azure as SECONDARY failover |
| **CI/CD IAM** | OIDC-based authentication for GitHub Actions (no stored credentials) |
| **ACR (Azure)** | Azure Container Registry with Premium SKU and geo-replication |
| **AKS Clusters (Azure)** | Kubernetes 1.34 clusters in eastus and westus2 (optional failover target) |
| **Demo Application** | Sample microservice deployed with 3 replicas and LoadBalancer |

## Prerequisites

- **AWS CLI** configured with appropriate credentials
- **Azure CLI** (optional, for Azure deployment)
- **Terraform** >= 1.12.0
- **kubectl** for Kubernetes cluster management
- **make** for running workflow commands
- An AWS account with permissions to create EKS, ECR, IAM, Route53, and VPC resources
- An Azure subscription (optional, for cross-cloud failover)

## Project Structure

```
aws_infrastructure/
├── environments/
│   └── development/
│       ├── main.tf              # Main config (ECR, EKS, Route53 failover)
│       ├── variables.tf         # Input variables with defaults
│       ├── outputs.tf           # Exported values
│       ├── providers.tf         # AWS provider configuration
│       ├── data.tf              # Data sources (VPCs, subnets, Route53 zone)
│       ├── backend.tf           # S3/DynamoDB remote state config
│       ├── Makefile             # Development workflow commands
│       ├── k8s/
│       │   ├── app.yaml         # Demo application deployment
│       │   ├── debug.yaml       # Debug pod configuration
│       │   └── node-reader-sa.yaml  # Service account for node info
│       ├── load-time.sh         # Response time measurement script
│       └── empty-ecr.sh         # ECR cleanup utility
│
└── modules/
    ├── ecr/                     # ECR repository module
    ├── eks/                     # EKS cluster module (wraps terraform-aws-modules/eks)
    ├── cicd-iam/                # GitHub Actions OIDC authentication
    └── remote_state/            # Terraform state backend (S3 + DynamoDB)

azure_infrastructure/
├── environments/
│   └── development/
│       ├── main.tf              # Main config (ACR, AKS clusters)
│       ├── variables.tf         # Input variables with defaults
│       ├── outputs.tf           # Exported values
│       ├── providers.tf         # Azure provider configuration
│       ├── backend.tf           # Azure Storage remote state config
│       ├── Makefile             # Development workflow commands
│       └── k8s/
│           ├── app.yaml         # Demo application deployment
│           └── node-reader-sa.yaml  # Service account for node info
│
└── modules/
    ├── acr/                     # Azure Container Registry with geo-replication
    ├── aks/                     # AKS cluster module
    └── remote-state/            # Terraform state backend (Azure Storage)
```

## Setup & Deployment

### AWS Infrastructure

#### 1. Configure Environment Variables

Create a `.env` file in `aws_infrastructure/` with your configuration:

```bash
REMOTE_BUCKET_NAME=your-terraform-state-bucket
REMOTE_DYNAMODB_TABLE=your-terraform-lock-table
AWS_DEFAULT_REGION=us-east-1
```

#### 2. Initialize Terraform

```bash
cd aws_infrastructure/environments/development
make init
```

#### 3. Plan and Apply Infrastructure

```bash
# Review changes
make plan

# Apply infrastructure
make apply
```

This will create:
- ECR repositories in us-east-1 and us-west-2
- Cross-region replication from east to west
- EKS clusters in both regions
- IAM policies for ECR access and cluster administration

#### 4. Configure kubectl Access

```bash
# Set up kubeconfig for east cluster
make kubeconfig-east

# Set up kubeconfig for west cluster
make kubeconfig-west
```

#### 5. Deploy the Demo Application

```bash
# Switch to east cluster
make use-east

# Deploy the application
make deploy-app

# Repeat for west cluster
make use-west
make deploy-app
```

#### 6. Configure Route53 DNS (After Application Deployment)

After deploying the application, get the LoadBalancer hostnames and update `variables.tf`:

```hcl
lb_hostname_east = "your-east-lb-hostname.elb.amazonaws.com"
lb_hostname_west = "your-west-lb-hostname.elb.amazonaws.com"
```

Re-run `make plan && make apply` to create the Route53 health checks and weighted routing records.

### Azure Infrastructure (Optional)

#### 1. Configure Environment Variables

Create a `.env` file in `azure_infrastructure/` with your configuration:

```bash
STORAGE_ACCOUNT_NAME=your-storage-account
CONTAINER_NAME=tfstate
STATE_RESOURCE_GROUP=your-state-rg
```

#### 2. Initialize and Deploy

```bash
cd azure_infrastructure/environments/development
make init
make plan
make apply
```

This will create:
- ACR with Premium SKU and geo-replication (eastus → westus2)
- AKS clusters in both regions
- AcrPull role assignments for cluster identities

#### 3. Deploy Application to AKS

```bash
# Switch to east cluster and deploy
make use-east
make deploy-app

# Repeat for west cluster
make use-west
make deploy-app
```

#### 4. Enable Cross-Cloud Failover

After deploying to both AWS and Azure, get the Azure LoadBalancer IPs:

```bash
make get-lb-ips
```

Update AWS `variables.tf` to enable cross-cloud failover:

```hcl
enable_cross_cloud_failover = true
azure_lb_ip_east            = "x.x.x.x"
azure_lb_ip_west            = "x.x.x.x"
```

Re-run AWS Terraform to create failover routing (AWS primary, Azure secondary).

## Usage

### Switching Between Clusters

```bash
# Switch kubectl context to us-east-1 cluster
make use-east

# Switch kubectl context to us-west-2 cluster
make use-west
```

### Testing the Application

```bash
# Ping the LoadBalancer service endpoint
make ping-service

# Test via DNS record (if configured)
make ping-dns-record
```

### Measuring Response Time

```bash
# Run 10 requests and calculate average response time
./load-time.sh
```

### Terraform Operations

```bash
make lint      # Format and validate Terraform
make plan      # Preview changes
make apply     # Apply changes
make refresh   # Refresh state
make destroy   # Tear down all infrastructure
make clean     # Remove local Terraform files
```

### ECR Management

```bash
# Empty ECR repositories (required before destroy)
make empty-ecr
```

## Configuration

### AWS Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | Primary AWS region |
| `cluster_name` | `eks-cluster-dev` | Base name for EKS clusters |
| `cluster_version` | `1.34` | Kubernetes version |
| `repository_name` | `basic-demo-microservice-01` | ECR repository name |
| `domain_name` | - | Root domain for Route53 hosted zone |
| `subdomain` | `eks-demo` | Subdomain for failover record |
| `lb_hostname_east` | `""` | East region LoadBalancer hostname |
| `lb_hostname_west` | `""` | West region LoadBalancer hostname |
| `enable_cross_cloud_failover` | `false` | Enable nested routing with Azure failover |
| `azure_lb_ip_east` | `""` | Azure East US LoadBalancer IP |
| `azure_lb_ip_west` | `""` | Azure West US 2 LoadBalancer IP |
| `aws_pool_subdomain` | `aws-pool` | Subdomain for AWS weighted pool |
| `aws_east_weight` | `50` | Traffic weight for East region (0-255) |
| `aws_west_weight` | `50` | Traffic weight for West region (0-255) |
| `elb_zone_id_east` | `Z35SXDOTRQ7X7K` | ELB hosted zone ID for us-east-1 |
| `elb_zone_id_west` | `Z1H1FL5HABSF5` | ELB hosted zone ID for us-west-2 |

### Azure Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `azure_region_east` | `eastus` | Primary Azure region |
| `azure_region_west` | `westus2` | Secondary Azure region |
| `cluster_name` | `aks-cluster-dev` | Base name for AKS clusters |
| `kubernetes_version` | `1.29` | Kubernetes version |
| `registry_name` | `aksmultiregiondemoacr` | ACR name (globally unique) |
| `vm_size` | `Standard_B2s` | VM size for AKS nodes |

### Node Group Configuration

**AWS EKS:**
```hcl
eks_managed_node_groups = {
  eks_nodes = {
    desired_size   = 3
    max_size       = 6
    min_size       = 3
    instance_types = ["t3.small"]
  }
}
```

**Azure AKS:**
```hcl
node_count = 3
min_count  = 3
max_count  = 6
vm_size    = "Standard_B2s"
```

## Demo Application

The included demo application (`basic-demo-microservice-01`) demonstrates:

- **Multi-replica deployment** (3 pods per cluster)
- **LoadBalancer service** with `externalTrafficPolicy: Local` for reduced latency
- **Node awareness** via environment variables exposing the underlying node name
- **Service account** with permissions to read node information

### Application Manifest Highlights

```yaml
spec:
  replicas: 3
  template:
    spec:
      serviceAccountName: node-reader-sa
      containers:
        - name: basic-demo-microservice-01
          image: <account>.dkr.ecr.us-east-1.amazonaws.com/basic-demo-microservice-01:latest
          env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
```

## High Availability Features

1. **Cross-Region ECR Replication**: Images pushed to the primary repository (us-east-1) automatically replicate to the secondary (us-west-2), ensuring both clusters can pull images locally.

2. **Independent EKS Clusters**: Each region has its own fully functional Kubernetes cluster, providing isolation from regional failures.

3. **Route53 Nested Routing**: Two-tier DNS architecture ensures full multi-region coverage:
   - **AWS Pool** (`aws-pool.eks-demo.domain`): Weighted routing distributes traffic 50/50 between East and West
   - **Main Record** (`eks-demo.domain`): Failover routing with AWS pool as PRIMARY
   - Health checks monitor each LoadBalancer; unhealthy endpoints are automatically removed
   - Calculated health check aggregates both AWS regions (healthy if at least one region is up)

4. **Cross-Cloud Failover**: When `enable_cross_cloud_failover=true`, the nested routing enables automatic failover to Azure. Both AWS regions participate in normal traffic distribution. Failover to Azure only occurs when BOTH AWS regions are unhealthy.

5. **Azure Geo-Replication**: ACR with Premium SKU provides automatic geo-replication between eastus and westus2, ensuring local image pulls for both AKS clusters.

6. **Secure CI/CD Pipeline**: GitHub Actions authenticates via OIDC, eliminating the need for long-lived AWS credentials in your repository.

7. **Local Traffic Policy**: LoadBalancer services use `externalTrafficPolicy: Local` to route traffic to pods on the same node, reducing cross-AZ latency.

## Cleanup

### AWS Infrastructure

```bash
cd aws_infrastructure/environments/development

# This will empty ECR repos and destroy all resources
make destroy
```

### Azure Infrastructure

```bash
cd azure_infrastructure/environments/development

# This will empty ACR and destroy all resources
make destroy
```

## License

See [LICENSE](LICENSE) for details.
