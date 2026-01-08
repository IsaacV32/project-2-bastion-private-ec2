variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "bastion_key_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}
