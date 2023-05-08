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

  provisioner "remote-exec" {
    inline = [
      <<SCRIPT

			sudo apt update -y 
			sudo apt install nginx certbot python3-certbot-nginx -y 
			sudo rm /etc/nginx/sites-enabled/default
			sudo mv /var/www/html/index.nginx-debian.html /var/www/html/index.html 
      sudo mv /tmp/nginx-blocklist.conf /etc/nginx-blocklist.conf
			
      echo '${templatefile("${path.module}/conf/nginx.conf.tpl", { domain_name = var.domain_name, user_agent = var.user_agent })}' | sudo tee /etc/nginx/nginx.conf

			sudo certbot --nginx -d ${var.a_record_redirector} --non-interactive --agree-tos -m webmaster@${var.domain_name}
			sudo systemctl restart nginx 

			SCRIPT
    ]
  }

  provisioner "local-exec" {
    command = <<SCRIPT
			ssh -i ${var.ssh_private_key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_instance.http_redirector.public_ip} "sudo cat /etc/letsencrypt/live/${var.a_record_redirector}/fullchain.pem" > ./fullchain.pem
			ssh -i ${var.ssh_private_key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${aws_instance.http_redirector.public_ip} "sudo cat /etc/letsencrypt/live/${var.a_record_redirector}/privkey.pem" > ./privkey.pem
			SCRIPT  
  }
}