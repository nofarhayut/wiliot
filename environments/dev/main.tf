provider "aws" {
  region = var.region

  # Single ownership label on every AWS resource -> AWS cost allocation tag.
  default_tags {
    tags = {
      team = "devops"
    }
  }
}

# ---------- Foundation: VPC + IAM (no dependencies, applied first) ----------
module "network" {
  source = "../../modules/network"

  name                 = var.project
  vpc_cidr             = "10.0.0.0/16"
  azs                  = var.azs
  public_subnet_cidrs  = ["10.0.0.0/20", "10.0.16.0/20"]
  private_subnet_cidrs = ["10.0.32.0/20", "10.0.48.0/20"]
}

module "iam" {
  source = "../../modules/iam"
  name   = var.project
}

module "ecr" {
  source           = "../../modules/ecr"
  repository_names = ["${var.project}-datagen", "${var.project}-airflow-jobs"]
}

# ---------- EKS: depends on network + iam ----------
module "eks" {
  source = "../../modules/eks"

  cluster_name     = var.cluster_name
  subnet_ids       = module.network.private_subnet_ids
  cluster_role_arn = module.iam.cluster_role_arn
  node_role_arn    = module.iam.node_role_arn
}

# ---------- RDS: depends on network + eks (for source SG) ----------
module "rds" {
  source = "../../modules/rds"

  name                       = var.project
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
}
