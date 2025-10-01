region                      = "eu-central-1"
project_name                = "ecs-cluster"
environment                 = "test"
department                  = "IT"
vpc_cidr                    = "172.28.64.0/21"
public_subnet_az1_cidr      = "172.28.64.0/24"
public_subnet_az2_cidr      = "172.28.65.0/24"
private_app_subnet_az1_cidr = "172.28.66.0/24"
private_app_subnet_az2_cidr = "172.28.67.0/24"
private_data_subnet_az1     = "172.28.68.0/24"
private_data_subnet_az2     = "172.28.69.0/24"
global_tags = {
  project_name = "ecs"
  environment  = "test"
  department   = "IT"
}
#bastion
key_name              = "ec2-bastion"
instance_type         = "t3.micro"
bastion_instance_name = "bastion"
container_port        = "80"
container_name        = "nginx"
#ACM
domain_name               = "selflearner.click"
subject_alternative_names = "*.selflearner.click"
#ECS Service
container_image  = "mesxi1/nginx-mkhmaladze:latest"
ecs_service_name = "nginx"
web_site         = "nginx.selflearner.click"



