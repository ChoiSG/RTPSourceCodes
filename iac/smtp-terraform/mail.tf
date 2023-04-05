resource "digitalocean_droplet" "mail" {
  name   = "${var.mail}.${var.domain}"
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
      apt update -y
      export DEBIAN_FRONTEND=noninteractive
      apt install -y -qq socat postfix opendkim opendkim-tools certbot

      # Set hostname
      hostnamectl set-hostname mail
      myhostname="${var.mail}.${var.domain}"
      domain="${var.domain}"
      ip="${digitalocean_droplet.mail.ipv4_address}"
      gophiship="${digitalocean_droplet.gophish.ipv4_address}"

      # Set mailname and hosts file
      echo $domain > /etc/mailname
      echo $ip $domain > /etc/hosts

      # Configure Postfix
      postconf -e myhostname=$myhostname 
      postconf -e milter_protocol=2
      postconf -e milter_default_action=accept
      postconf -e smtpd_milters=inet:localhost:12345
      postconf -e non_smtpd_milters=inet:localhost:12345
      postconf -e mydestination="$domain, $myhostname, localhost.localdomain, localhost"
      postconf -e mynetworks="127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 $gophiship"

      # Configure DKIM 
      mkdir -p /etc/opendkim/keys/$domain 
      cd /etc/opendkim/keys/$domain 

      # Create dkim TXT record 
      opendkim-genkey -t -s mail -d $domain 
      cat mail.txt | tr -d '\n" ' | grep -o 'v=DKIM1.*' | cut -d ';' -f 1-5 | tr '\t' ' ' | tr -s ' ' | tr -d ')' > /root/dkim.txt 
      chown opendkim:opendkim mail.private 

      # Configure necessary files - KeyTable, SigningTable, default/opendkim, TrustedHosts 
      echo mail._domainkey.$domain $domain:mail:/etc/opendkim/keys/$domain/mail.private > /etc/opendkim/KeyTable 
      echo *@$domain mail._domainkey.$domain > /etc/opendkim/SigningTable 
      echo SOCKET=\"inet:12345@localhost\" >> /etc/default/opendkim 
      echo $gophiship > /etc/opendkim/TrustedHosts 
      echo *.$domain >> /etc/opendkim/TrustedHosts 
      echo localhost >> /etc/opendkim/TrustedHosts
      echo 127.0.0.1 >> /etc/opendkim/TrustedHosts

      # Restarting services. This might be changed to a reboot later on. Need testing. Terraform -> wait 10 min -> mail-tester
      sleep 2
      systemctl restart opendkim.service
      systemctl restart postfix.service
      sleep 2

      # Fetching dkim.txt 
      cp /root/dkim.txt /tmp/dkim_output.txt
      SCRIPT
    ]
  }
  provisioner "file" {
    source      = "./configs/master.cf"
    destination = "/etc/postfix/master.cf"
  }

  // do similar thing for opendkim.conf and header_checks 
  provisioner "file" {
    source      = "./configs/opendkim.conf"
    destination = "/etc/opendkim.conf"
  }

  provisioner "file" {
    source      = "./configs/header_checks"
    destination = "/etc/postfix/header_checks"
  }
}

// Null resource to prevent race condition
resource "null_resource" "fetch_dkim_output" {
  triggers = {
    droplet_id = digitalocean_droplet.mail.id
  }

  provisioner "local-exec" {
    command = "scp -i ${var.ssh_private_key} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${digitalocean_droplet.mail.ipv4_address}:/tmp/dkim_output.txt ${path.module}/dkim_output.txt"
  }
}

locals {
  dkim_output = fileexists("${path.module}/dkim_output.txt") && length(null_resource.fetch_dkim_output.id) > 0 ? trimspace(file("${path.module}/dkim_output.txt")) : ""
}

output "dkim_output" {
  value     = local.dkim_output
  sensitive = true
}
