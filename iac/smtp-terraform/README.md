# SMTP Terraform 
https://www.레드팀.com/infrastructure/mail-terraform

Simple SMTP terraform that builds a mail server and a gophish server on DigitalOcean. 
All credits goes to the authors in the credit section, the terraform scripts were recreated for my personal research and educational purposes. 

## Infra 
- Mail server with postfix (mail.domain.com) 
- Gophish server (login.domain.com)
- DNS records: SPF, DKIM, DMARC, rDNS, A 

## Usage 
1. Buy a domain in a domain registrar 
2. Change the domain nameserver to that of Digital Ocean's (ns1.digitalocean.com, ns2.digitalocean.com)
3. Create a digital ocean developer token 
4. Update the `variables.tf` and run the terraform script 
```
terraform init 
terraform plan  
terraform apply 
```

## Credits 
Most of the code are from:
- https://github.dev/b1gbroth3r/red-team-infrastructure-example
- https://github.com/mantvydasb/Red-Team-Infrastructure-Automation
- https://www.ired.team/offensive-security/red-team-infrastructure/automating-red-team-infrastructure-with-terraform
