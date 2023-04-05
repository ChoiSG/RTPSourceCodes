// Create new ssh key pair for this specific terraform project 
resource "digitalocean_ssh_key" "default" {
  name       = var.ssh_key_name
  public_key = file("${var.ssh_private_key}.pub")
}

resource "digitalocean_domain" "default" {
  name = var.domain
}

// Create Project. All resources will be joined AFTER they are created and configured. 
resource "digitalocean_project" "default" {
  name        = var.projectName
  description = "Project for ${var.projectName}"
  purpose     = "Web Application"
  environment = "Production"
  resources = [
    digitalocean_droplet.mail.urn,
    digitalocean_droplet.gophish.urn,
    digitalocean_domain.default.urn
  ]
  depends_on = [
    digitalocean_droplet.mail,
    digitalocean_droplet.gophish,
    digitalocean_domain.default
  ]
}