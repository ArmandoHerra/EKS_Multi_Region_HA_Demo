data "aws_caller_identity" "current" {}

# Primary repository in us-east-1
module "ecr_primary" {
  source          = "../../modules/ecr"
  repository_name = var.repository_name
  region_suffix   = "east"
  providers = {
    aws = aws
  }
}

# Secondary repository in us-west-2
module "ecr_secondary" {
  source          = "../../modules/ecr"
  repository_name = var.repository_name
  region_suffix   = "west"
  providers = {
    aws = aws.us_west
  }
}

# Set up cross-region replication from primary to secondary.
# This resource uses the primary provider.
resource "aws_ecr_replication_configuration" "replication" {
  replication_configuration {
    rule {
      # Replicate images to us-west-2.
      destination {
        region      = "us-west-2"
        registry_id = data.aws_caller_identity.current.account_id
      }

      # This rule applies to repositories with names that start with the given prefix.
      repository_filter {
        filter      = var.repository_name
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}
