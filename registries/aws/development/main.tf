module "ecr_primary" {
  source          = "../../../aws_infrastructure/modules/ecr"
  repository_name = var.repository_name
  region_suffix   = "east"
  providers = {
    aws = aws
  }
}

module "ecr_secondary" {
  source          = "../../../aws_infrastructure/modules/ecr"
  repository_name = var.repository_name
  region_suffix   = "west"
  providers = {
    aws = aws.us_west
  }
}

resource "aws_ecr_replication_configuration" "replication" {
  replication_configuration {
    rule {
      destination {
        region      = "us-west-2"
        registry_id = data.aws_caller_identity.current.account_id
      }
      repository_filter {
        filter      = var.repository_name
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}
