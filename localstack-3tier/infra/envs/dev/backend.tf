terraform {
  backend "s3" {
    bucket         = "tfstate-arjun"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-locks"
    endpoint       = "http://localhost:4566"
    force_path_style = true
  }
}
