# data.tf

data "aws_caller_identity" "current" {}

# Data source for the default VPC in us-east-1
data "aws_vpc" "default_east" {
  default = true
}

# Data source for subnets in the default VPC in us-east-1
data "aws_subnets" "default_subnets_east" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_east.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }
}

# Data source for the default VPC in us-west-2
data "aws_vpc" "default_west" {
  provider = aws.us_west
  default  = true
}

# Data source for subnets in the default VPC in us-west-2
data "aws_subnets" "default_subnets_west" {
  provider = aws.us_west
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_west.id]
  }

  filter {
    name   = "availability-zone"
    values = ["us-west-2a", "us-west-2b", "us-west-2c"]
  }
}

# Use local values to pick the first 3 subnets from each list.
locals {
  east_subnet_ids = data.aws_subnets.default_subnets_east.ids
  west_subnet_ids = data.aws_subnets.default_subnets_west.ids
}
