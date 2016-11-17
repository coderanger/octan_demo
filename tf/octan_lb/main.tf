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

variable "vpc_id" {}

variable "subnets" {
  type = "list"
}

variable "instance_port" {
  default = "80"
}

variable "instance_protocol" {
  default = "http"
}

variable "internal" {
  default = false
}

variable "health_check_path" {
  default = "/"
}

# Security group
resource "aws_security_group" "elb" {
  name_prefix = "elb-${var.name}-"
  description = "Allow inbound HTTP traffic to the ELB"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name} ELB security group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Load balancer
resource "aws_elb" "default" {
  subnets         = ["${var.subnets}"]
  security_groups = ["${aws_security_group.elb.id}"]
  internal        = "${var.internal}"

  listener {
    # TODO These should both be HTTPS in real life
    instance_port     = "${var.instance_port}"
    instance_protocol = "${var.instance_protocol}"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    target              = "HTTP:${var.instance_port}${var.health_check_path}"
    interval            = 5
  }

  tags {
    Name = "${var.name}"
  }
}

output "id" {
  value = "${aws_elb.default.id}"
}

output "dns_name" {
  value = "${aws_elb.default.dns_name}"
}
