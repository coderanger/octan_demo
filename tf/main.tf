provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "companyNews VPC"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

module "xenial_small_ami" {
  source = "github.com/terraform-community-modules/tf_aws_ubuntu_ami/ebs"
  region = "${var.region}"
  distribution = "xenial"
  instance_type = "t2.micro"
  storagetype = "ebs-ssd"
}

module "xenial_big_ami" {
  source = "github.com/terraform-community-modules/tf_aws_ubuntu_ami/ebs"
  region = "${var.region}"
  distribution = "xenial"
  instance_type = "m4.large"
  storagetype = "ebs-ssd"
}

module "zone_a" {
  source = "./company_zone"
  name = "a"
  region = "${var.region}"
  vpc_id = "${aws_vpc.default.id}"
  gateway_id = "${aws_internet_gateway.default.id}"
  big_ami_id = "${module.xenial_big_ami.ami_id}"
  small_ami_id = "${module.xenial_small_ami.ami_id}"
  public_cidr = "${var.public_cidr["a"]}"
  staging_cidr = "${var.staging_cidr["a"]}"
  production_cidr = "${var.production_cidr["a"]}"
}

module "zone_b" {
  source = "./company_zone"
  name = "b"
  region = "${var.region}"
  vpc_id = "${aws_vpc.default.id}"
  gateway_id = "${aws_internet_gateway.default.id}"
  big_ami_id = "${module.xenial_big_ami.ami_id}"
  small_ami_id = "${module.xenial_small_ami.ami_id}"
  public_cidr = "${var.public_cidr["b"]}"
  staging_cidr = "${var.staging_cidr["b"]}"
  production_cidr = "${var.production_cidr["b"]}"
}

# ELB
