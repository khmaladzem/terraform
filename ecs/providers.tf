provider "aws" {
  region  = var.region
  profile = "default"

  default_tags {
    tags = {
      Environment = var.environment
      Department  = var.department
      Name        = "${var.project_name}-ecs"
    }
  }
}