// Mail section 

resource "digitalocean_record" "mail" {
  domain = var.domain
  type   = "A"
  name   = "${var.mail}"
  value  = digitalocean_droplet.mail.ipv4_address
  ttl    = 600
}

resource "digitalocean_record" "mail_mx" {
  domain   = var.domain
  type     = "MX"
  name     = "@"
  value    = "${var.mail}.${var.domain}."
  priority = 10
  ttl      = 600
}

resource "digitalocean_record" "dkim" {
  domain = var.domain
  type   = "TXT"
  name   = "mail._domainkey"
  value  = local.dkim_output
  ttl    = 600
  depends_on = [digitalocean_droplet.mail]
}

resource "digitalocean_record" "spf" {
  domain = var.domain
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 a mx ip4:${digitalocean_droplet.mail.ipv4_address} ~all"
  ttl    = 600
}

resource "digitalocean_record" "dmarc" {
  domain = var.domain
  type   = "TXT"
  name   = "_dmarc"
  value  = "v=DMARC1; p=reject"
  ttl    = 600
}

// gophish section 
resource "digitalocean_record" "gophish" {
  domain = var.domain
  type   = "A"
  name   = "${var.gophish}"
  value  = digitalocean_droplet.gophish.ipv4_address
  ttl    = 600
}