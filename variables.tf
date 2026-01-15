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
  description = "Existing VPC ID from Project 1"
  type        = string
}

variable "public_subnet_ids" {
  description = "Existing public subnet IDs from Project 1"
  type        = list(string)
}
variable "private_subnet_ids" {
  description = "Existing private subnet IDs from Project 1"
  type        = list(string)
}
