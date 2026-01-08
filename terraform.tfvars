project_name     = "example-project"
environment      = "dev"
allowed_ssh_cidr = "203.0.113.0/32"
bastion_key_name = "example-key"

# Replace with your real VPC id
vpc_id = "vpc-0123456789abcdef0"

# Replace with one or more subnet ids
public_subnet_ids = [
  "subnet-0123456789abcdef0",
  "subnet-0fedcba9876543210",
]
