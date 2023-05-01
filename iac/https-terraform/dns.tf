resource "aws_route53_record" "redirector_A_record" {
  zone_id = var.domain_zone_id
  name    = var.a_name
  type    = "A"
  ttl     = "300"
  records = [aws_instance.http_redirector.public_ip]
}