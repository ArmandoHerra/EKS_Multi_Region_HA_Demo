provider "aws" {
  region = var.aws_region
}

# Create the OIDC provider for GitHub Actions.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Build the conditions for the trust policy. If a subject restriction is provided, include it.
locals {
  oidc_conditions = var.github_oidc_subject != "" ? {
    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
    "token.actions.githubusercontent.com:sub" = var.github_oidc_subject
    } : {
    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
  }
}

# Create the CI/CD role that can be assumed via GitHub Actions' OIDC.
resource "aws_iam_role" "ci_cd_role" {
  name = "ci-cd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = local.oidc_conditions
        }
      }
    ]
  })
}

# Attach an inline policy to the CI/CD role with permissions limited to ECR push/pull.
resource "aws_iam_role_policy" "ci_cd_role_policy" {
  name = "ci-cd-role-policy"
  role = aws_iam_role.ci_cd_role.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "AllowPushPull",
        Effect : "Allow",
        Action : [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        Resource : "arn:aws:ecr:${var.aws_region}:${var.aws_account_id}:repository/${var.repository_name}*"
      },
      {
        Sid : "AllowGetAuthToken",
        Effect : "Allow",
        Action : "ecr:GetAuthorizationToken",
        Resource : "*"
      }
    ]
  })
}
