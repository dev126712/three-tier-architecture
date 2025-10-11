variable "aws_region" {
  default = "ca-central-1"
  type    = string
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
  type    = string
}

variable "availability-zone-1" {
  default = "ca-central-1a"
  type    = string
}
variable "availability-zone-2" {
  default = "ca-central-1b"
  type    = string
}



variable "public-subnet-bastion-host-cidr-block" {
  default = "10.0.1.0/24"
  type    = string
}

variable "public-subnet-nat-gateway-cidr-block" {
  default = "10.0.2.0/24"
  type    = string
}

variable "private-web-subnet-1-cidr_block" {
  default = "10.0.3.0/24"
  type    = string
}

variable "private-web-subnet-2-cidr_block" {
  default = "10.0.4.0/24"
  type    = string
}

variable "private-app-subnet-1-cidr_block" {
  default = "10.0.5.0/24"
  type    = string
}

variable "private-app-subnet-2-cidr_block" {
  default = "10.0.6.0/24"
  type    = string
}



variable "private-db-subnet-1-cidr_block" {
  default = "10.0.7.0/24"
  type    = string
}

variable "private-db-subnet-2-cidr_block" {
  default = "10.0.8.0/24"
  type    = string
}


variable "amis" {
  default = ""
  type    = string
}

variable "instance_type" {
  default = "t2.micro"
  type    = string
}