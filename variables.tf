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


variable "enable_s3_cleanup" {
   description = "Set to true to enable S3 cleanup functionality in the Lambda."
   type        = bool
   default     = false
}

variable "s3_bucket_name" {
   description = "The name of the S3 bucket to clean up (if enable_s3_cleanup is true)."
   type        = string
   default     = "hcltrainings"
}

variable "s3_prefix" {
   description = "The S3 prefix (folder) to clean up within the bucket (if enable_s3_cleanup is true)."
   type        = string
   default     = "2tier/"
}