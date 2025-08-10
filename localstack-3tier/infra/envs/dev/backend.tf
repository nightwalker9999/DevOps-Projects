terraform {
  backend "s3" {
    bucket = "tfstate-arjun"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"

    # Legacy-compatible settings for LocalStack
    endpoint         = "http://localhost:4566"
    force_path_style = true

    # Keep DDB locking for parity with real AWS teams
    dynamodb_table = "tfstate-locks"
  }
}