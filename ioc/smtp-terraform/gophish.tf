resource "digitalocean_droplet" "gophish" {
  name   = "${var.gophish}.${var.domain}"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"

  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

resource "digitalocean_project_resources" "gophish" {
  project = var.projectID
  resources = [
    digitalocean_droplet.gophish.urn
  ]
}