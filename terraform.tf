terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  required_version = ">= 1.0"
  
  backend "s3" {
    # Backend configuration will be provided via terraform init -backend-config
    # This ensures the state is stored remotely with locking support
  }
}
