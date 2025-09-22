module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name                 = "my-vpc"
  cidr                 = "10.0.0.0/16"
  enable_dns_hostnames = true

  azs            = ["eu-central-1a", "eu-central-1b"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}



module "ssh_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "Bastion-sg"
  description = "Bastion host security group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH  port for bastion"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.1.1"

  name = "Bastion"

  instance_type               = "t3.micro"
  key_name                    = "ec2-bastion"
  monitoring                  = false
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.ssh_security_group.security_group_id]
  associate_public_ip_address = true
  create_security_group       = false


  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}