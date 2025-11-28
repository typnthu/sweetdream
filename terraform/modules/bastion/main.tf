# Bastion Host Module - Temporary EC2 for RDS Access

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Security Group for Bastion
resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  # Allow SSH from anywhere (you can restrict this to your IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-sg"
  })
}

# Update RDS security group to allow access from bastion
resource "aws_security_group_rule" "rds_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = var.rds_security_group_id
  description              = "PostgreSQL from bastion"
}

# IAM Role for EC2 (for SSM Session Manager - optional)
resource "aws_iam_role" "bastion" {
  name = "${var.name_prefix}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach SSM policy for Session Manager
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile
resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name_prefix}-bastion-profile"
  role = aws_iam_role.bastion.name

  tags = var.tags
}

# EC2 Key Pair (optional - for SSH access)
resource "aws_key_pair" "bastion" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.name_prefix}-bastion-key"
  public_key = var.ssh_public_key

  tags = var.tags
}

# Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  key_name               = var.create_key_pair ? aws_key_pair.bastion[0].key_name : null

  # User data to install PostgreSQL client
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y postgresql15
              
              # Create a helper script for database connection
              cat > /home/ec2-user/connect-db.sh << 'SCRIPT'
              #!/bin/bash
              echo "Connecting to RDS..."
              psql -h ${var.db_host} -U ${var.db_username} -d ${var.db_name}
              SCRIPT
              
              chmod +x /home/ec2-user/connect-db.sh
              chown ec2-user:ec2-user /home/ec2-user/connect-db.sh
              
              # Create admin check script
              cat > /home/ec2-user/check-admin.sh << 'SCRIPT'
              #!/bin/bash
              echo "Checking admin accounts..."
              psql -h ${var.db_host} -U ${var.db_username} -d ${var.db_name} -c "SELECT id, name, email, role FROM customers WHERE role = 'ADMIN';"
              SCRIPT
              
              chmod +x /home/ec2-user/check-admin.sh
              chown ec2-user:ec2-user /home/ec2-user/check-admin.sh
              EOF

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion"
  })
}

# Elastic IP for bastion (optional - for consistent IP)
resource "aws_eip" "bastion" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-eip"
  })
}
