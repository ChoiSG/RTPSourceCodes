output "outputs" {
  value = <<EOF
  
  << HTTP Redirector Created >> 

  [+] VPC created           = ${aws_vpc.redteam_vpc.id}
  [+] Subnet created        = ${aws_subnet.public_subnet.id}
  [+] HTTP Redirector DNS   = ${var.a_record_redirector} 
  [+] HTTP Redirector IP    = ${aws_instance.http_redirector.public_ip}
  [+] SSL Fullchain.pem     = ${path.module}/fullchain.pem
  [+] SSL privkey.pem       = ${path.module}/privkey.pem
  [+] Allowlist User Agent  = ${var.user_agent}
  [+] Allowlist IP          = ${var.operatorip}

  [+] Run the following SSH command for SSH Remote Port Forwarding: 
    
    ssh -i ${var.ssh_private_key} ubuntu@${var.a_record_redirector} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -R 2222:127.0.0.1:443
  
  EOF 
}
