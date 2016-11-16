#
# Copyright 2016, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

variable "name" {
  description = "Availablity zone letter for this zone"
}

variable "region" {
  description = "AWS region for this zone"
}

variable "vpc_id" {
  description = "VPC ID for this zone"
}

variable "gateway_id" {
  description = "Internet gateway ID corresponding to thie VPC for this zone"
}

variable "big_ami_id" {
  description = "AMI ID to use for m4.large instances"
}

variable "small_ami_id" {
  description = "AMI ID to use for t2.micro instances"
}

variable "public_cidr" {
  description = "CIDR IP block for the public subnet in this zone"
}

variable "staging_cidr" {
  description = "CIDR IP block for the staging subnet in this zone"
}

variable "production_cidr" {
  description = "CIDR IP block for the public subnet in this zone"
}

variable "chef_url_base" {
  description = "URL base for downloading Chef policy archives"
}

variable "staging_fe_elb" {
  description = "Name of the frontend staging load balancer"
}

variable "staging_be_elb" {}

variable "production_fe_elb" {}

variable "production_be_elb" {}

# TODO Cheapo service discovery, should either be a static-ish name or use Consul
variable "staging_be_elb_dns" {}

variable "production_be_elb_dns" {}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.public_cidr}"
  availability_zone = "${var.region}${var.name}"

  tags {
    Name = "Octan ${var.region}${var.name} public subnet"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.gateway_id}"
  }

  tags {
    Name = "Octan ${var.region}${var.name} public route table"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

# NAT
resource "aws_eip" "nat" {
  vpc = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public.id}"

  lifecycle {
    create_before_destroy = true
  }
}

# Bastion host
resource "aws_security_group" "bastion" {
  name_prefix = "bastion"
  description = "Allow inbound SSH traffic to the bastion hosts"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Octan ${var.region}${var.name} bastion security group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "bastion_bootstrap" {
  # This is sad-panda encapsulation breaking, needs a refactor.
  template = "${file("${path.module}/../octan_cluster/bootstrap.tpl")}"

  vars {
    chef_policy_url = "${var.chef_url_base}/bastion.tgz"
    extra_config    = "{}"
  }
}

# Use a single instance here instead of an ASG so we can get the IP for the outputs
# It could use a TCP-mode ELB instead but it makes host keys painful
resource "aws_instance" "bastion" {
  ami                         = "${var.small_ami_id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.public.id}"
  vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]
  associate_public_ip_address = true
  user_data                   = "${data.template_file.bastion_bootstrap.rendered}"

  tags {
    Name = "Octan ${var.region}${var.name} bastion host"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Environments
module "staging_environment" {
  source            = "../octan_env"
  name              = "staging"
  region            = "${var.region}"
  vpc_id            = "${var.vpc_id}"
  availability_zone = "${var.region}${var.name}"
  big_ami_id        = "${var.big_ami_id}"
  small_ami_id      = "${var.small_ami_id}"
  private_cidr      = "${var.staging_cidr}"
  nat_gateway       = "${aws_nat_gateway.nat.id}"
  chef_url_base     = "${var.chef_url_base}"
  fe_elb            = "${var.staging_fe_elb}"
  be_elb            = "${var.staging_be_elb}"
  be_elb_dns        = "${var.staging_be_elb_dns}"
}

# module "production_environment" {
#   source = "./octan_env"
#   name = "production"
#   private_cidr = "${var.production_cidr}"
# }

output "public_subnet" {
  value = "${aws_subnet.public.id}"
}

output "staging_subnet" {
  value = "${module.staging_environment.subnet_id}"
}

output "production_subnet" {
  value = ""
}

output "bastion_host" {
  value = "${aws_instance.bastion.public_ip}"
}
