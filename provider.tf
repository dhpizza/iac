
provider "aws" {
  region = "eu-west-1"
  version = "~> 2"
}

terraform {
  backend "local" {
    path = "../tf/tfstate"
  }
}
