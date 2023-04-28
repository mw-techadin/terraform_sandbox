provider "aws" {
  region = var.region
}

locals {
  cluster_name = "your-cluster-name"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = local.cluster_name
  }
}

resource "aws_subnet" "this" {
  count = length(var.subnet_cidr_blocks)

  cidr_block = var.subnet_cidr_blocks[count.index]
  vpc_id     = aws_vpc.this.id

  tags = {
    Name = "${local.cluster_name}-subnet-${count.index}"
  }
}

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = aws_vpc.this.id
}

resource "aws_security_group_rule" "worker_group_mgmt_one" {
  security_group_id = aws_security_group.worker_group_mgmt_one.id

  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/8"]
}

resource "aws_security_group_rule" "worker_group_mgmt_two" {
  security_group_id = aws_security_group.worker_group_mgmt_two.id

  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["172.16.0.0/12"]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.cluster_name
  cidr = var.vpc_cidr_block

  azs             = var.availability_zones
  private_subnets = var.subnet_cidr_blocks
  public_subnets  = var.subnet_cidr_blocks

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }

  vpc_tags = {
    Name = local.cluster_name
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name = local.cluster_name
  subnets      = module.vpc.private_subnets

  tags = {
    Terraform = "true"
    Environment = "dev"
  }

  vpc_id = aws_vpc.this.id

  kubeconfig_aws_authenticator_env_variables = {
    AWS_PROFILE = "default"
  }

  kubeconfig_name = local.cluster_name

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 20
  }

  node_groups = {
    eks_nodes = {
      desired_capacity = var.node_pool_initial_node_count
      max_capacity     = var.node_pool_max_node_count
      min_capacity     = var.node_pool_min_node_count

      instance_type = var.node_pool_instance_type
      additional_tags = {
        your_label_key = "your_label_value"
      }
    }
  }
}

# Replace the values in the variables with your specific parameters
variable "region" {
  default = "us-west-2"
