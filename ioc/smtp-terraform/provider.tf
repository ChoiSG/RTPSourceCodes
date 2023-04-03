terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.10.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

// Create new ssh key pair for this specific terraform project 
resource "digitalocean_ssh_key" "default" {
  name       = "tftesto"
  public_key = file("${var.ssh_private_key}.pub")
}