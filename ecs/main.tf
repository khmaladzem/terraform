
locals {
  name     = var.project_name
  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
  tags     = var.global_tags
}
data "aws_availability_zones" "available" {}

#AMI data sources
data "aws_ami" "latest_al2023_arm64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html#ecs-optimized-ami-linux
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

module "vpc" {
  source                       = "terraform-aws-modules/vpc/aws"
  version                      = "~> 6.0.1"
  name                         = var.project_name
  cidr                         = local.vpc_cidr
  azs                          = local.azs
  enable_dns_hostnames         = true
  private_subnets              = [var.private_app_subnet_az1_cidr, var.private_app_subnet_az2_cidr]
  public_subnets               = [var.public_subnet_az1_cidr, var.public_subnet_az2_cidr]
  database_subnets             = [var.private_data_subnet_az1, var.private_data_subnet_az2]
  create_database_subnet_group = true
  enable_nat_gateway           = true
  single_nat_gateway           = true
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



module "bastion_ec2_instance" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 6.1.1"
  name                        = var.bastion_instance_name
  instance_type               = var.instance_type
  ami                         = data.aws_ami.latest_al2023_arm64.id
  key_name                    = var.key_name
  monitoring                  = false
  vpc_security_group_ids      = [module.ssh_security_group.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  create_security_group       = false
  user_data                   = file("${path.module}/bastion.tpl")

  metadata_options = {
    http_tokens = "optional"
  }

}




resource "aws_eip" "bastion" {
  domain   = "vpc"
  instance = module.bastion_ec2_instance.id
  tags = {
    Name = "Basetion_eip"
  }
}



module "ecs_cluster" {
  source       = "terraform-aws-modules/ecs/aws"
  version      = "6.1.3"
  cluster_name = var.project_name
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "9.0.1"

  for_each = {
    # On-demand instances
    ex_1 = {
      instance_type              = var.instance_type
      use_mixed_instances_policy = false
      mixed_instances_policy     = {}
      user_data                  = file("${path.module}/userdata.sh")
    }

  }

  name                            = "${local.name}-${each.key}"
  image_id                        = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  instance_type                   = each.value.instance_type
  security_groups                 = [module.autoscaling_sg.security_group_id, module.ssh_security_group.security_group_id]
  user_data                       = base64encode(each.value.user_data)
  key_name                        = var.key_name
  launch_template_version         = "$Default"
  ignore_desired_capacity_changes = true
  create_iam_instance_profile     = true
  iam_role_name                   = local.name
  iam_role_description            = "ECS role for ${local.name}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 2

  # https://github.com/hashicorp/terraform-provider-aws/issues/12582
  autoscaling_group_tags = {
    AmazonECSManaged = true,

    Department  = var.department,
    environment = var.environment

  }
  # Required for  managed_termination_protection = "ENABLED"
  protect_from_scale_in = false

}
########################################################################

module "autoscaling_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 5.0"
  name        = local.name
  description = "Autoscaling group security group"
  vpc_id      = module.vpc.vpc_id
  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.alb.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
  egress_rules                                             = ["all-all"]
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = local.name

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # For example only
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    },
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }

  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {

    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.acm.acm_certificate_arn
      forward = {
        target_group_key = "nginx"
      }

      rules = [
        {
          priority = 100,
          actions = [
            {
              type             = "forward",
              target_group_key = "nginx"
            }
          ],
          conditions = [
            {
              host_header = {
                values = ["nginx.selflearner.click"] # Replace with a valid hostname
              }
            }
          ]
        },

      ]
    }

  }



  target_groups = {
    nginx = {
      name_prefix          = "nginx"
      protocol             = "HTTP"
      port                 = 80
      target_type          = "instance"
      deregistration_delay = 5

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 5
        matcher             = "200,301,302"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 4
        unhealthy_threshold = 2
      }
      create_attachment = false
    }

  }

}

data "aws_route53_zone" "selected_zone" {
  name         = "selflearner.click." # Replace with your Hosted Zone name
  private_zone = false                # Set to true if it's a private hosted zone

}

module "acm" {
  source                    = "terraform-aws-modules/acm/aws"
  version                   = "~> 4.0"
  domain_name               = var.domain_name
  zone_id                   = data.aws_route53_zone.selected_zone.zone_id
  validation_method         = "DNS"
  subject_alternative_names = [var.domain_name, var.subject_alternative_names]
  wait_for_validation       = true
  create_route53_records    = true

}



module "ecs_service_nginx" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "6.1.3"


  name                = var.ecs_service_name
  cluster_arn         = module.ecs_cluster.cluster_arn
  desired_count       = 2
  launch_type         = "EC2"
  network_mode        = "bridge"
  scheduling_strategy = "DAEMON"
  cpu                 = null
  memory              = "512"

  container_definitions = {

    nginx = {
      # cpu       = 0
      memory    = "512"
      essential = true
      image     = var.container_image
      portMappings = [
        {
          name          = var.container_name
          containerPort = 80
          protocol      = "tcp"
          hostPort      = 8080
        }
      ]
      environment = [

      ]

      # Example image used requires access to write to root filesystem
      readonlyRootFilesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["nginx"].arn
      container_name   = var.container_name
      container_port   = 80
    }
  }
  create_task_definition   = true
  requires_compatibilities = ["EC2"]

}



resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected_zone.zone_id
  name    = var.web_site
  type    = "A"
  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}


