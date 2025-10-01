variable "region" {}
variable "project_name" {}
variable "environment" {}
variable "department" {}

#VPC Variables
variable "vpc_cidr" {}
variable "public_subnet_az1_cidr" {}
variable "public_subnet_az2_cidr" {}
variable "private_app_subnet_az1_cidr" {}
variable "private_app_subnet_az2_cidr" {}
variable "private_data_subnet_az1" {}
variable "private_data_subnet_az2" {}
variable "global_tags" {}
#Bastion
variable "key_name" {}
variable "instance_type" {}
variable "bastion_instance_name" {}

#ACM
variable "domain_name" {}
variable "subject_alternative_names" {}

#ECS Service
variable "container_name" {}
variable "container_port" {}
variable "ecs_service_name" {}
variable "container_image" {}
#Web site
variable "web_site" {}
