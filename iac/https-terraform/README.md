# HTTPS Terraform - AWS 

This is a proof of concept terraform script to build a simple HTTP/S redirector in AWS. 

1. Creates a vpc, subnet, internet gateway, and routing table 
2. Starts an EC2 instance, install & configures nginx for redirector purposes 
3. Creates an A record in Route53, if and only if the hosting zone already exists. 

Redirector Configuration:

1. IP blocklist of famous scanners, bad IP ranges, etc. 
2. Allowlisted User-Agent string 
3. Redirects any bad traffic to www.google.com by default 

## Prerequisites 
1. Create AWS Route53 Hosted zone. Then, get the Hosted Zone ID from Route53 (`/route53/v2/hostedzones`) and update `variables.tf`.
2. Change domain registrar's nameserver to AWS's NS 
3. `aws configure` with your terraform IAM user creds from AWS 
4. Update `variables.tf` 

(Optional) 5. If you have custom nginx.conf from havoc2nginx or cs2nginx, place it in the ./conf/nginx.conf and terraform will use that config file.

## Usage 
```
└─# terraform init
└─# terraform fmt
└─# terraform plan 
└─# terraform apply 

[ . . . ] 

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

outputs = <<EOT
  
  << HTTP Redirector Created >> 

  [+] VPC created           = vpc-080595e6981db6853
  [+] Subnet created        = subnet-0670c640e73a5d76b
  [+] HTTP Redirector DNS   = blog.grootbaon.com 
  [+] HTTP Redirector IP    = 54.198.134.47
  [+] SSL Fullchain.pem     = ./fullchain.pem
  [+] SSL privkey.pem       = ./privkey.pem
  [+] Allowlist User Agent  = Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36
  [+] Allowlist IP          = REDACTED/32

  [+] Run the following SSH command for SSH Remote Port Forwarding: 
    
    ssh -i ./groot-redteam ubuntu@blog.grootbaon.com -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -R 2222:127.0.0.1:443
```

With the redirector ready, SSH remote port forward, update the C2 malleable C2 profile with correct host (`blog.domain.com` and user-agent), and catch the agent callback.

```
ssh -i <ssh-priv-key> ubuntu@<redir-dns> -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -R 2222:127.0.0.1:443
```


## Reference 
- IP Blocklist: https://github.com/mgeeky/RedWarden
- IP Blocklist: https://github.com/fin3ss3g0d/evilgophish
- Nginx configuration: https://github.com/threatexpress/cs2modrewrite