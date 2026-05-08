variable "aws_region" {}
variable "key_name" {}
variable "db_username" {}
variable "db_password" {}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
}

variable "api_url" {
  description = "API URL for the frontend to connect to the backend"
  type        = string
  default     = ""
}
