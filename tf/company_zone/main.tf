variable "name" {}
variable "region" {}
variable "vpc_id" {}
variable "gateway_id" {}
variable "big_ami_id" {}
variable "small_ami_id" {}
variable "public_cidr" {}
variable "staging_cidr" {}
variable "production_cidr" {}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.public_cidr}"
  availability_zone = "${var.region}${var.name}"

  tags {
    Name = "${var.region}${var.name} public subnet"
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
    Name = "${var.region}${var.name} public route table"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.public.id}"
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
  subnet_id = "${aws_subnet.public.id}"

  lifecycle {
    create_before_destroy = true
  }
}

# Bastion host
resource "aws_security_group" "bastion" {
  name_prefix = "bastion"
  description = "Allow inbound SSH traffic to the bastion hosts"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 0
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.region}${var.name} bastion security group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "bastion" {
  ami = "${var.small_ami_id}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public.id}"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  associate_public_ip_address = true

  key_name = "ec2" # TODO: Fix this later

  tags {
    Name = "${var.region}${var.name} bastion host"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Environments
module "staging_environment" {
  source = "../company_environment"
  name = "staging"
  vpc_id = "${var.vpc_id}"
  availability_zone = "${var.region}${var.name}"
  big_ami_id = "${var.big_ami_id}"
  small_ami_id = "${var.small_ami_id}"
  private_cidr = "${var.staging_cidr}"
  nat_gateway = "${aws_nat_gateway.nat.id}"
}

# module "production_environment" {
#   source = "./company_environment"
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
