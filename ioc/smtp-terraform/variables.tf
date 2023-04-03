variable "do_token" {
  default = "<token>"
}

variable "ssh_private_key" {
  type        = string
  description = "The path to the SSH private key to use for authentication."
  default     = "<fullfilepath>"
}

variable "domain" {
  default = "domain.com"
}

variable "gophish" {
  default = "login"
}

variable "projectID" {
  default = "<projectID>"
}

variable "mail" {
  default = "mail"
}