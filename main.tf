provider "aws" {
  profile    = "personal"
  version = "~> 2.0"
  region = var.region
}

terraform {
    backend "remote" {
      hostname = "app.terraform.io"
      organization = "blackcat"

      workspaces {
        name = "aws-west-mids-demo"
      }
    }
}
