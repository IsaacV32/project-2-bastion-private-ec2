data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
  description = "Bastion host security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from trusted IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-bastion-sg"
  })
}
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.bastion_key_name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = <<-EOF
              #!/bin/bash
              set -euo pipefail
              dnf -y update
              dnf -y install htop jq
              echo "Bastion ready: $(date)" > /etc/motd
              EOF

  tags = merge(var.tags, {
    Name = "${var.project_name}-bastion"
    Role = "bastion"
  })
}
resource "aws_security_group" "private_ec2_sg" {
  name        = "${var.project_name}-private-ec2-sg"
  description = "Private EC2 security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-ec2-sg"
  })
}
resource "aws_launch_template" "private_lt" {
  name_prefix   = "${var.project_name}-private-"
  image_id      = data.aws_ami.al2023.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -euo pipefail
              dnf -y update
              echo "ASG instance ready" > /etc/motd
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.project_name}-private-asg"
      Role = "private"
    })
  }
}
resource "aws_autoscaling_group" "private_asg" {
  name             = "${var.project_name}-private-asg"
  desired_capacity = 2
  min_size         = 1
  max_size         = 3

  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.private_lt.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${var.project_name}-private-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "private"
    propagate_at_launch = true
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}
