# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1" # Mumbai region
}

variable "project_name" {
  description = "A unique name for your project, used as a prefix for resources."
  type        = string
  default     = "my-scheduled-app"
}

