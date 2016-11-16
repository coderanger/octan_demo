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

# Install nginx
package 'nginx'

# Unpack the static assets
directory '/srv/octan' do
  owner 'root'
  group 'root'
  mode '755'
end

poise_archive 'https://s3.amazonaws.com/infra-assessment/static.zip' do
  destination '/srv/octan/static'
end

# Configure nginx vhost
service 'nginx' do
  action :nothing
end

file '/etc/nginx/sites-enabled/default' do
  action :delete
  notifies :restart, 'service[nginx]'
end

template '/etc/nginx/sites-enabled/octan' do
  source 'nginx.conf.erb'
  owner 'root'
  group 'root'
  mode '644'
  notifies :restart, 'service[nginx]'
  variables backend_elb: node['octan']['backend_lb']
end
