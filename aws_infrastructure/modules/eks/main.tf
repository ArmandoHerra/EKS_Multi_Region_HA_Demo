provider "aws" {
  region = var.region
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.34.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnets

  eks_managed_node_groups = var.eks_managed_node_groups
  cluster_endpoint_public_access = true
  cluster_endpoint_public_access_cidrs =  [ "0.0.0.0/0" ]
  enable_cluster_creator_admin_permissions = true

  # Optionally, attach additional policies to node IAM roles.
  iam_role_additional_policies = {
    ecr = var.ecr_policy_arn
  }

  tags = var.tags
}