variable "app" {
  description = "Application name, this should be unique"
  type        = string
}

variable "bucket" {
  description = "Application bucket name, this should be unique on aws"
  type        = string
}

variable "db_instance" {
  description = "Database instance type, this should be unique on aws"
  type        = string
  default     = "db.t2.micro"
}

variable "db_name" {
  description = "Database instance name and root user, this should be unique on aws"
  type        = string
}

variable "client" {
  description = "Client name owner of the resources"
  type        = string
  default     = "***********"
}

variable "environment" {
  description = "Environment type"
  type        = string
  default     = "production"
}

variable "region" {
  description = "AWS region type"
  type        = string
  default     = "sa-east-1"
}

variable "tags" {
  description = "A mapping of tags to assign to resources."
  type        = map(string)
}

variable "container_port" {
  description = "Container server listening port"
  type        = number
}

variable "private_subnets" {
  description = "The private subnets, minimum of 2, that are a part of the VPC(s)"
  type        = string
}

variable "vpc_id" {
  description = "VPC id to deploy infrastructure"
  type        = string
}

variable "lb_port" {
  description = "VPC id to deploy infrastructure"
  type        = string
}

variable "lb_protocol" {
  description = "VPC id to deploy infrastructure"
  type        = string
}

locals {
  namespace      = "${var.app}-${var.environment}"
  target_subnets = split(",", var.private_subnets)
}