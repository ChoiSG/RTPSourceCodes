// Mail section 

resource "digitalocean_record" "mail" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = var.mail
  value  = digitalocean_droplet.mail.ipv4_address
  ttl    = 600
}

resource "digitalocean_record" "mail_mx" {
  domain   = digitalocean_domain.default.name
  type     = "MX"
  name     = "@"
  value    = "${var.mail}.${digitalocean_domain.default.name}."
  priority = 10
  ttl      = 600
}

resource "digitalocean_record" "dkim" {
  domain     = digitalocean_domain.default.name
  type       = "TXT"
  name       = "mail._domainkey"
  ttl        = 600
  value      = local.dkim_output
  depends_on = [null_resource.fetch_dkim_output]
}


resource "digitalocean_record" "spf" {
  domain = digitalocean_domain.default.name
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 a mx ip4:${digitalocean_droplet.mail.ipv4_address} ~all"
  ttl    = 600
}

// dmarc with v=DMARC1; p=reject 
resource "digitalocean_record" "dmarc" {
  domain = digitalocean_domain.default.name
  type   = "TXT"
  name   = "_dmarc"
  value  = "v=DMARC1; p=reject"
  ttl    = 600
}

// gophish section 
resource "digitalocean_record" "gophish" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = var.gophish
  value  = digitalocean_droplet.gophish.ipv4_address
  ttl    = 600
}