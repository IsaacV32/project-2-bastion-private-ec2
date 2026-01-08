module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids

  allowed_ssh_cidr = var.allowed_ssh_cidr
  bastion_key_name = var.bastion_key_name

  tags = {
    Environment = var.environment
  }
}
