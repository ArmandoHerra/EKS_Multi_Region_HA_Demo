# EKS Multi-Region High Availability Demo

A demonstration of Multi-Region High Availability architecture using Amazon EKS, showcasing cross-region container registry replication, dual Kubernetes clusters, and secure CI/CD integration with GitHub Actions.

## Architecture Overview

This project deploys a fully redundant infrastructure across two AWS regions:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                      │
│                                                                             │
│   ┌─────────────────────────────┐      ┌─────────────────────────────┐      │
│   │        us-east-1            │      │        us-west-2            │      │
│   │                             │      │                             │      │
│   │  ┌───────────────────────┐  │      │  ┌───────────────────────┐  │      │
│   │  │    ECR Repository     │──┼──────┼──│    ECR Repository     │  │      │
│   │  │  (Primary - Push)     │  │ Repl │  │  (Secondary - Pull)   │  │      │
│   │  └───────────────────────┘  │      │  └───────────────────────┘  │      │
│   │                             │      │                             │      │
│   │  ┌───────────────────────┐  │      │  ┌───────────────────────┐  │      │
│   │  │   EKS Cluster East    │  │      │  │   EKS Cluster West    │  │      │
│   │  │   (3 t3.small nodes)  │  │      │  │   (3 t3.small nodes)  │  │      │
│   │  │                       │  │      │  │                       │  │      │
│   │  │  ┌─────────────────┐  │  │      │  │  ┌─────────────────┐  │  │      │
│   │  │  │  Demo App (x3)  │  │  │      │  │  │  Demo App (x3)  │  │  │      │
│   │  │  └─────────────────┘  │  │      │  │  └─────────────────┘  │  │      │
│   │  │          │            │  │      │  │          │            │  │      │
│   │  │  ┌───────▼───────┐    │  │      │  │  ┌───────▼───────┐    │  │      │
│   │  │  │ LoadBalancer  │    │  │      │  │  │ LoadBalancer  │    │  │      │
│   │  │  └───────────────┘    │  │      │  │  └───────────────┘    │  │      │
│   │  └───────────────────────┘  │      │  └───────────────────────┘  │      │
│   └─────────────────────────────┘      └─────────────────────────────┘      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                          ┌──────────▼──────────┐
                          │   GitHub Actions    │
                          │   (OIDC Auth)       │
                          └─────────────────────┘
```

### Key Components

| Component | Description |
|-----------|-------------|
| **ECR Repositories** | Container registries in both regions with automatic cross-region replication |
| **EKS Clusters** | Kubernetes 1.34 clusters with managed node groups (3-6 nodes each) |
| **CI/CD IAM** | OIDC-based authentication for GitHub Actions (no stored credentials) |
| **Demo Application** | Sample microservice deployed with 3 replicas and LoadBalancer |

## Prerequisites

- **AWS CLI** configured with appropriate credentials
- **Terraform** >= 1.0
- **kubectl** for Kubernetes cluster management
- **make** for running workflow commands
- An AWS account with permissions to create EKS, ECR, IAM, and VPC resources

## Project Structure

```
aws_infrastructure/
├── environments/
│   └── development/
│       ├── main.tf              # Main configuration (ECR + EKS modules)
│       ├── variables.tf         # Input variables with defaults
│       ├── outputs.tf           # Exported values
│       ├── providers.tf         # AWS provider configuration
│       ├── data.tf              # Data sources (VPCs, subnets)
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
```

## Setup & Deployment

### 1. Configure Environment Variables

Create a `.env` file in `aws_infrastructure/` with your configuration:

```bash
REMOTE_BUCKET_NAME=your-terraform-state-bucket
REMOTE_DYNAMODB_TABLE=your-terraform-lock-table
AWS_DEFAULT_REGION=us-east-1
```

### 2. Initialize Terraform

```bash
cd aws_infrastructure/environments/development
make init
```

### 3. Plan and Apply Infrastructure

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

### 4. Configure kubectl Access

```bash
# Set up kubeconfig for east cluster
make kubeconfig-east

# Set up kubeconfig for west cluster
make kubeconfig-west
```

### 5. Deploy the Demo Application

```bash
# Switch to east cluster
make use-east

# Deploy the application
make deploy-app

# Repeat for west cluster
make use-west
make deploy-app
```

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

### Default Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | Primary AWS region |
| `cluster_name` | `eks-cluster-dev` | Base name for EKS clusters |
| `cluster_version` | `1.34` | Kubernetes version |
| `repository_name` | `basic-demo-microservice-01` | ECR repository name |

### Node Group Configuration

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

3. **Secure CI/CD Pipeline**: GitHub Actions authenticates via OIDC, eliminating the need for long-lived AWS credentials in your repository.

4. **Local Traffic Policy**: LoadBalancer services use `externalTrafficPolicy: Local` to route traffic to pods on the same node, reducing cross-AZ latency.

## Cleanup

To destroy all infrastructure:

```bash
cd aws_infrastructure/environments/development

# This will empty ECR repos and destroy all resources
make destroy
```

## License

See [LICENSE](LICENSE) for details.
