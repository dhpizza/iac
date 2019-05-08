terraform {
  backend "s3" {
    bucket = "jambit-iac-terraform"
    key = "dheerema/terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  version = "~> 2" # terraform plugin version => 2
  region = "eu-west-1"
}
