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

variable "subnet" {}

variable "chef_policy_url" {}

variable "iam_policy" {
  default = <<EOH
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOH
}

variable "ami_id" {}

variable "instance_type" {
  default = "m4.large"
}

variable "load_balancer" {}

variable "extra_config" {
  type    = "map"
  default = {}
}

variable "port" {
  default = 80
}

# IAM role and related
resource "aws_iam_role" "cluster" {
  name_prefix = "${var.name}-"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cluster" {
  name   = "${var.name}_policy"
  role   = "${aws_iam_role.cluster.id}"
  policy = "${var.iam_policy}"
}

resource "aws_iam_instance_profile" "cluster" {
  name_prefix = "${var.name}-"
  roles       = ["${aws_iam_role.cluster.name}"]
}

# Security group
resource "aws_security_group" "cluster" {
  name_prefix = "${var.name}-"

  # TODO This should be using HTTPS if it were for real.
  description = "Allow inbound SSH and HTTP traffic to the app hosts"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = "${var.port}"
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
    Name = "${var.region} ${var.name} security group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Userdata script template
data "template_file" "bootstrap" {
  template = "${file("${path.module}/bootstrap.tpl")}"

  vars {
    chef_policy_url = "${var.chef_policy_url}"
    extra_config    = "${jsonencode(var.extra_config)}"
  }
}

# Launch config
resource "aws_launch_configuration" "cluster" {
  name_prefix     = "${var.name}-"
  image_id        = "${var.ami_id}"
  instance_type   = "${var.instance_type}"
  user_data       = "${data.template_file.bootstrap.rendered}"
  security_groups = ["${aws_security_group.cluster.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

# Autoscaling group
resource "aws_autoscaling_group" "cluster" {
  launch_configuration = "${aws_launch_configuration.cluster.name}"
  load_balancers       = ["${var.load_balancer}"]
  vpc_zone_identifier  = ["${var.subnet}"]

  # TODO: Fix this
  min_size = 1
  max_size = 1

  tag {
    key                 = "Name"
    value               = "Octan ${var.name}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
