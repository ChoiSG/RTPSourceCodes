#
# Redirector.tf: Build and configure redirector server with nginx. 
# If ./conf/nginx.conf is provided by the operator using havoc2nginx or cs2nginx, use that. 
# If not, use the very dbasic nginx.conf.tpl template file for minimal opsec. 
#

resource "aws_instance" "http_redirector" {
  ami                    = "ami-007855ac798b5175e"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.ssh_key_operator.id
  vpc_security_group_ids = [aws_security_group.redirector_sg.id]
  depends_on             = [aws_internet_gateway.gw]

  tags = {
    Name = "http-redirector"
  }
}

locals {
  nginx_conf_exists = fileexists("${path.module}/conf/nginx.conf")
}

resource "null_resource" "http_redirector_provision" {
  triggers = {
    instance_id = aws_instance.http_redirector.id
    record_id   = aws_route53_record.redirector_A_record.id
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_private_key)
    host        = aws_instance.http_redirector.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/conf/blocklist.conf"
    destination = "/tmp/nginx-blocklist.conf"
  }

  provisioner "file" {
    when        = create
    on_failure = continue
    source = "${path.module}/conf/nginx.conf"
    destination = "/tmp/nginx.conf"
  }

  # Concat instead of heredoc because of nginx.conf existence conditional. 
  provisioner "remote-exec" {
    inline = concat([
      "sudo apt update -y",
      "sudo apt install nginx nginx-extras certbot python3-certbot-nginx -y",
      "sudo mv /var/www/html/index.nginx-debian.html /var/www/html/index.html",
      "sudo mv /tmp/nginx-blocklist.conf /etc/nginx-blocklist.conf"
    ],
    local.nginx_conf_exists ? [
      "sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf"
    ] : [
      "echo '${templatefile("${path.module}/conf/nginx.conf.tpl", { domain_name = var.domain_name, user_agent = var.user_agent })}' | sudo tee /etc/nginx/nginx.conf"
    ],
    [
      "sudo certbot --nginx -d ${var.a_record_redirector} --non-interactive --agree-tos -m webmaster@${var.domain_name}",
      "sudo systemctl restart nginx"
    ])
  }


  provisioner "local-exec" {
    command = <<SCRIPT
			ssh -i ${var.ssh_private_key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_instance.http_redirector.public_ip} "sudo cat /etc/letsencrypt/live/${var.a_record_redirector}/fullchain.pem" > ./fullchain.pem
			ssh -i ${var.ssh_private_key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_instance.http_redirector.public_ip} "sudo cat /etc/letsencrypt/live/${var.a_record_redirector}/privkey.pem" > ./privkey.pem
			SCRIPT  
  }
}