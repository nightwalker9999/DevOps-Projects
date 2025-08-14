terraform {
  backend "s3" {
    bucket         = "tfstate-arjun"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    force_path_style = true

    # LocalStack endpoint overrides
    endpoints = {
      s3        = "http://localhost:4566"
      dynamodb  = "http://localhost:4566"
      sts       = "http://localhost:4566"
    }

    dynamodb_table = "tfstate-locks"
  }
}