# UPDATE the variables as needed, then run terraform

variable "operatorip" {
  description = "Source IP address of the operator"
  default     = "0.0.0.0/32"
}

variable "domain_name" {
  description = "Domain name for the engagement"
  default     = "grootbaon.com"
}

variable "domain_zone_id" {
  description = "Domain zone ID of the domain in Route53"
  default     = "Z00925761JQBXL67T13WH"
}

variable "a_record_redirector" {
  description = "A record for the redirector"
  default     = "blog.grootbaon.com"
}

variable "a_name" {
  description = "A record name"
  default     = "blog"
}

variable "user_agent" {
  description = "User agent to block"
  default     = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36"
}

variable "projectname" {
  description = "Name of the project"
  default     = "grootredteam"
}

variable "ssh_public_key" {
  description = "SSH public key file of the operator"
  default     = "/root/grootredteam/grootssh.pub"
}

variable "ssh_private_key" {
  description = "SSH private key of the operator"
  default     = "/root/grootredteam/grootssh"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC for engagement ABC"
  default     = "10.100.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  default     = "10.100.1.0/24"
}