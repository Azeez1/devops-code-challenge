variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tf_state_bucket" {
  description = "Name of S3 bucket for Terraform state"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the ALB and ECS cluster are deployed."
  type        = string
  default     = "vpc-07255e0202157ef09" // Set your VPC ID here
}

variable "tf_state_lock_table" {
  description = "Name of DynamoDB table for state locking"
  type        = string
}

variable "backend_image_tag" {
  description = "The ECR tag for the backend image to deploy"
  type        = string
}

variable "frontend_image_tag" {
  description = "The ECR tag for the frontend image to deploy"
  type        = string
}
variable "public_subnets" {
  description = "A list of public subnet IDs for the ALB."
  type        = list(string)
  # You'll need to provide actual subnet IDs, e.g., through a .tfvars file or Jenkins
  # Example default (REPLACE WITH YOUR ACTUAL SUBNET IDs):
  # default = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
}
