output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}
output "private_asg_name" {
  value = module.compute.private_asg_name
}
