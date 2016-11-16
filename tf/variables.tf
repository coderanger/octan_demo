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

variable "region" {
  description = "EC2 region"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default     = "10.0.0.0/16"
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
