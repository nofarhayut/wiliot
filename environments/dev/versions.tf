terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }

  # Remote state in S3. Native S3 locking (use_lockfile) — no DynamoDB needed
  # on Terraform >= 1.10. Create the bucket first via scripts/bootstrap-backend.sh.
  backend "s3" {
    bucket       = "wiliot-tfstate-092988563851"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
