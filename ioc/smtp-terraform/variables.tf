// REDACT SECTION
variable "do_token" {
  default = "REDACTED"
}
// REDACT SECTION

variable "ssh_private_key" {
  type        = string
  description = "The path to the SSH private key to use for authentication."
  default     = "/root/rtp/tftesto"
}

variable "ssh_key_name" {
  default = "tftesto"
}

variable "projectName" {
  default = "koreambtihealth.com"
}

variable "domain" {
  default = "koreambtihealth.com"
}

variable "gophish" {
  default = "login"
}

variable "mail" {
  default = "mail"
}