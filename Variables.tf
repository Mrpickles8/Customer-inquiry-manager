variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "project_name" {
  type    = string
  default = "customer-inquiry"
}


variable "db_password" {
  description = "RDS MySQL password"
  type        = string
  sensitive   = true

}


variable "db_user" {
  description = "RDS MySQL user"
  type        = string
  sensitive   = true
}


variable "sender_email" {
  type      = string
  sensitive = true
}

variable "admin_email" {
  type      = string
  sensitive = true
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
