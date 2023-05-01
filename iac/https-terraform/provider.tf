terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Choose the desired AWS region
}

# TODO: add tag 
resource "aws_key_pair" "ssh_key_operator" {
  key_name   = "ssh_key_operator"
  public_key = file(var.ssh_public_key)
}