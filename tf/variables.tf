variable "region" {
  description = "EC2 region"
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default = "10.0.0.0/16"
}

variable "public_cidr" {
  description = "CIDR for the public subnets"
  default = {
    a = "10.0.0.0/24"
    b = "10.0.1.0/24"
  }
}

variable "staging_cidr" {
  description = "CIDR for the private staging subnets"
  default = {
    a = "10.0.2.0/24"
    b = "10.0.3.0/24"
  }
}

variable "production_cidr" {
  description = "CIDR for the private production subnets"
  default = {
    a = "10.0.4.0/24"
    b = "10.0.5.0/24"
  }
}
