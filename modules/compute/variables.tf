variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "allowed_ssh_cidr" {
  type = string
}

variable "bastion_key_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "bastion_instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t3.micro"
}
variable "private_subnet_ids" {
  description = "List of private subnet IDs (Multi-AZ)"
  type        = list(string)
}
