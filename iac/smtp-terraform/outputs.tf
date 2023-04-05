// Straight from https://raw.githubusercontent.com/mantvydasb/Red-Team-Infrastructure-Automation/master/outputs.tf
output "outputs" {
  value = <<EOF
  // INFRA 
  phishing - ${var.mail}.${var.domain} - ${digitalocean_droplet.mail.ipv4_address}
  phishing - ${var.gophish}.${var.domain} - ${digitalocean_droplet.gophish.ipv4_address}

  // MISC 
  Gophish rid changed to: clientID

  // TODOs 
  Start gophish with: 
  ssh -i ${var.ssh_private_key} root@${var.gophish}.${var.domain} -L 3333:127.0.0.1:3333
  EOF 
}