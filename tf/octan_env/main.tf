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

variable "name" {}

variable "region" {}

variable "vpc_id" {}

variable "availability_zone" {}

variable "big_ami_id" {}

variable "small_ami_id" {}

variable "private_cidr" {}

variable "nat_gateway" {}

variable "chef_url_base" {}

variable "fe_elb" {}

variable "be_elb" {}

variable "be_elb_dns" {}

# Private subnet for this environment
resource "aws_subnet" "private" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.private_cidr}"
  availability_zone = "${var.availability_zone}"

  tags {
    Name = "${var.availability_zone} ${var.name} subnet"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Routing between the private subnet and the NAT gateway
resource "aws_route_table" "private" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${var.nat_gateway}"
  }

  tags {
    Name = "${var.availability_zone} ${var.name} route table"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

# Create the frontend application cluster
module "frontend_cluster" {
  source          = "../octan_cluster"
  name            = "${var.name}-frontend"
  region          = "${var.region}"
  vpc_id          = "${var.vpc_id}"
  subnet          = "${aws_subnet.private.id}"
  chef_policy_url = "${var.chef_url_base}/frontend.tgz"
  ami_id          = "${var.big_ami_id}"
  load_balancer   = "${var.fe_elb}"

  extra_config = {
    backend_lb = "${var.be_elb_dns}"
  }
}

# Create the backend application cluster
module "backend_cluster" {
  source          = "../octan_cluster"
  name            = "${var.name}-backend"
  region          = "${var.region}"
  vpc_id          = "${var.vpc_id}"
  subnet          = "${aws_subnet.private.id}"
  chef_policy_url = "${var.chef_url_base}/backend.tgz"
  ami_id          = "${var.big_ami_id}"
  load_balancer   = "${var.be_elb}"
  port            = 8000
}

output "subnet_id" {
  value = "${aws_subnet.private.id}"
}
