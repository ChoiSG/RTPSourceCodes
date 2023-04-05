resource "digitalocean_droplet" "gophish" {
  name   = "${var.gophish}.${var.domain}"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"

  ssh_keys = [digitalocean_ssh_key.default.fingerprint]

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.ssh_private_key)
    timeout     = "120s"
  }

  provisioner "remote-exec" {
    inline = [
      <<SCRIPT
      apt update -y ; apt install golang-go gcc -y 
      cd /opt 
      git clone https://github.com/gophish/gophish.git
      cd ./gophish 

      # Opsec changes 
      find . -type f -name "config.go" -exec sed -i 's/const ServerName = "gophish"/const ServerName = "IGNORE"/g' {} + 
      find . -type f -name "campaign.go" -exec sed -i 's/const RecipientParameter = "rid"/const RecipientParameter = "clientID"/g' {} + 
      find . -type f -exec sed -i 's/X-Gophish-Contact/X-Contact/g; s/X-Gophish-Signature/X-Signature/g' {} +

      go build 

      SCRIPT
    ]
  }
}