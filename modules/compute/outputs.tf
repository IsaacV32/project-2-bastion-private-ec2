output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}
output "private_asg_name" {
  value = aws_autoscaling_group.private_asg.name
}

