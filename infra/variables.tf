# infra/variables.tf

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tf_state_bucket" {
  description = "Name of S3 bucket for Terraform state"
  type        = string
  # No default, should be in tfvars
}

variable "vpc_id" {
  description = "The ID of the VPC where the ALB and ECS cluster are deployed."
  type        = string
  default     = "vpc-07255e0202157ef09" // Your VPC ID
}

variable "tf_state_lock_table" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  # No default, should be in tfvars
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
  description = "A list of public subnet IDs for the ALB. Must be at least two from different AZs."
  type        = list(string)
  # No default, values should be provided in terraform.tfvars
}
