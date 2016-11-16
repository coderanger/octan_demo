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

# Apt update so package installs work
apt_update 'update'

# Create a sample admin user
user 'octan' do
  manage_home true
  shell '/bin/bash'
end

# Set up SSH key authentication
directory '/home/octan/.ssh' do
  owner 'octan'
  group 'octan'
  mode '700'
end

cookbook_file '/home/octan/.ssh/authorized_keys' do
  source 'authorized_keys'
  owner 'octan'
  group 'octan'
  mode '644'
end

# Configure sudo
include_recipe 'sudo'

sudo 'octan' do
  user 'octan'
  nopasswd true
end
