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

# Set up the provider for AWS in the requested region
# Authentication credentials are assumed to be in environment variables
provider "aws" {
  region = "${var.region}"
}

# Create the VPC and its internet uplink
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name = "companyNews VPC"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grab AMI IDs for the two instance sizes we are using
module "xenial_small_ami" {
  source        = "github.com/terraform-community-modules/tf_aws_ubuntu_ami/ebs"
  region        = "${var.region}"
  distribution  = "xenial"
  instance_type = "t2.micro"
  storagetype   = "ebs-ssd"
}

module "xenial_big_ami" {
  source        = "github.com/terraform-community-modules/tf_aws_ubuntu_ami/ebs"
  region        = "${var.region}"
  distribution  = "xenial"
  instance_type = "m4.large"
  storagetype   = "ebs-ssd"
}

# Upload the Chef policies to S3
module "chef" {
  source = "./chef"
  region = "${var.region}"
}

# Create the EBS volumes for prevayler storage
resource "aws_ebs_volume" "staging_prevayler" {
  # This has to be in one AZ or the other, meaning bad stuff may happen if there
  # is both a server failure and inter-AZ split brain. No real way around that.
  availability_zone = "${var.region}a"

  size = 1

  tags {
    Name = "Octan staging prevayler storage"
  }
}

resource "aws_ebs_volume" "production_prevayler" {
  # This has to be in one AZ or the other, meaning bad stuff may happen if there
  # is both a server failure and inter-AZ split brain. No real way around that.
  availability_zone = "${var.region}a"

  size = 1

  tags {
    Name = "Octan production prevayler storage"
  }
}

# Create the two availability zones
module "zone_a" {
  source                = "./octan_zone"
  name                  = "a"
  region                = "${var.region}"
  vpc_id                = "${aws_vpc.default.id}"
  gateway_id            = "${aws_internet_gateway.default.id}"
  big_ami_id            = "${module.xenial_big_ami.ami_id}"
  small_ami_id          = "${module.xenial_small_ami.ami_id}"
  public_cidr           = "${var.public_cidr["a"]}"
  staging_cidr          = "${var.staging_cidr["a"]}"
  production_cidr       = "${var.production_cidr["a"]}"
  chef_url_base         = "${module.chef.url_base}"
  staging_fe_elb        = "${module.staging-frontend.id}"
  staging_be_elb        = "${module.staging-backend.id}"
  staging_be_elb_dns    = "${module.staging-backend.dns_name}"
  production_fe_elb     = "${module.production-frontend.id}"
  production_be_elb     = "${module.production-backend.id}"
  production_be_elb_dns = "${module.production-backend.dns_name}"
  staging_volume        = "${aws_ebs_volume.staging_prevayler.id}"
  production_volume     = "${aws_ebs_volume.production_prevayler.id}"
}

module "zone_b" {
  source                = "./octan_zone"
  name                  = "b"
  region                = "${var.region}"
  vpc_id                = "${aws_vpc.default.id}"
  gateway_id            = "${aws_internet_gateway.default.id}"
  big_ami_id            = "${module.xenial_big_ami.ami_id}"
  small_ami_id          = "${module.xenial_small_ami.ami_id}"
  public_cidr           = "${var.public_cidr["b"]}"
  staging_cidr          = "${var.staging_cidr["b"]}"
  production_cidr       = "${var.production_cidr["b"]}"
  chef_url_base         = "${module.chef.url_base}"
  staging_fe_elb        = "${module.staging-frontend.id}"
  staging_be_elb        = "${module.staging-backend.id}"
  staging_be_elb_dns    = "${module.staging-backend.dns_name}"
  production_fe_elb     = "${module.production-frontend.id}"
  production_be_elb     = "${module.production-backend.id}"
  production_be_elb_dns = "${module.production-backend.dns_name}"
  staging_volume        = "${aws_ebs_volume.staging_prevayler.id}"
  production_volume     = "${aws_ebs_volume.production_prevayler.id}"
}

# Create the four load balancers
module "staging-frontend" {
  source            = "./octan_lb"
  name              = "Octan staging frontend load balancer"
  vpc_id            = "${aws_vpc.default.id}"
  subnets           = ["${module.zone_a.public_subnet}", "${module.zone_b.public_subnet}"]
  health_check_path = "/images/logo.png"
}

module "staging-backend" {
  source        = "./octan_lb"
  name          = "Octan staging backend load balancer"
  vpc_id        = "${aws_vpc.default.id}"
  subnets       = ["${module.zone_a.staging_subnet}", "${module.zone_b.staging_subnet}"]
  instance_port = 8000
  internal      = true
}

module "production-frontend" {
  source            = "./octan_lb"
  name              = "Octan production frontend load balancer"
  vpc_id            = "${aws_vpc.default.id}"
  subnets           = ["${module.zone_a.public_subnet}", "${module.zone_b.public_subnet}"]
  health_check_path = "/images/logo.png"
}

module "production-backend" {
  source        = "./octan_lb"
  name          = "Octan production backend load balancer"
  vpc_id        = "${aws_vpc.default.id}"
  subnets       = ["${module.zone_a.production_subnet}", "${module.zone_b.production_subnet}"]
  instance_port = 8000
  internal      = true
}
