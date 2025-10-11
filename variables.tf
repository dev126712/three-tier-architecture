variable "aws_region" {
  default = "ca-central-1"
  type    = string
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
  type    = string
}

variable "availability-zone" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["ca-central-1a", "ca-central-1b"]
}

variable "public-subnet-bastion-host-cidr-block" {
  default = "10.0.1.0/24"
  type    = string
}

variable "public-subnet-nat-gateway-cidr-block" {
  default = "10.0.2.0/24"
  type    = string
}

variable "private-web-subnet-cidr_block" {
  type        = list(string)
  description = "ptivate web subnet cidr block values"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "private-app-subnet-cidr_block" {
  type        = list(string)
  description = "ptivate app subnet cidr block values"
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "private-db-subnet-cidr_block" {
  type        = list(string)
  description = "ptivate db subnet cidr block values"
  default     = ["10.0.7.0/24", "10.0.8.0/24"]
}

variable "amis" {
  default = "ami-0f39ffd6e446bf727"
  type    = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}