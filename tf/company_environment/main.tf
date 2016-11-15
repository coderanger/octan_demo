variable "name" {}
variable "vpc_id" {}
variable "availability_zone" {}
variable "big_ami_id" {}
variable "small_ami_id" {}
variable "private_cidr" {}
variable "nat_gateway" {}

# Private subnet
resource "aws_subnet" "private" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.private_cidr}"
  availability_zone = "${var.availability_zone}"

  tags {
    Name = "${var.availability_zone} ${var.name} subnet"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${var.vpc_id}"
  route {
    cidr_block = "0.0.0.0/0"
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
  subnet_id = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

# Test instance
resource "aws_security_group" "test" {
  name_prefix = "test"
  description = "Allow inbound SSH traffic to the test hosts"
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
    Name = "${var.availability_zone} ${var.name} test security group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "test" {
  ami = "${var.small_ami_id}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private.id}"
  vpc_security_group_ids = ["${aws_security_group.test.id}"]

  key_name = "ec2" # TODO: Fix this later

  tags {
    Name =  "${var.availability_zone} ${var.name} test host"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "subnet_id" {
  value = "${aws_subnet.private.id}"
}
