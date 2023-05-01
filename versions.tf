terraform {
  required_version = ">= 0.13.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
    sym = {
      source  = "symopsio/sym"
      version = "~> 2.0"
    }
  }
}
