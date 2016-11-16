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

variable "region" {}

# Internal use only, not actually intended to be set by users
variable "s3_region_map" {
  default = {
    us-east-1 = "s3.amazonaws.com"
  }
}

# Create an S3 bucket to hold Chef policy archives
resource "aws_s3_bucket" "chef" {
  region = "${var.region}"
  bucket = "octan-chef"
  acl    = "public-read"
}

# Upload the frontend policy archive
resource "aws_s3_bucket_object" "frontend_policy" {
  bucket = "${aws_s3_bucket.chef.id}"
  key    = "frontend.tgz"
  source = "policy_export/frontend.tgz"
  etag   = "${md5(file("policy_export/frontend.tgz"))}"
  acl    = "public-read"
}

# Upload the backend policy archive
resource "aws_s3_bucket_object" "backend_policy" {
  bucket = "${aws_s3_bucket.chef.id}"
  key    = "backend.tgz"
  source = "policy_export/backend.tgz"
  etag   = "${md5(file("policy_export/backend.tgz"))}"
  acl    = "public-read"
}

# Upload the bastion policy archive
resource "aws_s3_bucket_object" "bastion_policy" {
  bucket = "${aws_s3_bucket.chef.id}"
  key    = "bastion.tgz"
  source = "policy_export/bastion.tgz"
  etag   = "${md5(file("policy_export/bastion.tgz"))}"
  acl    = "public-read"
}

output "url_base" {
  value = "https://${lookup(var.s3_region_map, var.region, format("s3-%s.amazonaws.com", var.region))}/${aws_s3_bucket.chef.id}"
}
