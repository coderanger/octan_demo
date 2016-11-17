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

# Install awscli for the HA locking script
python_runtime '2'

python_package 'awscli'

# Install jq for the HA locking script
package 'jq'

# Install the JDK for Tomcat
package 'default-jdk'

# Install Tomcat
poise_archive 'http://apache.cs.utah.edu/tomcat/tomcat-8/v8.5.8/bin/apache-tomcat-8.5.8.zip' do
  destination '/opt/tomcat'
end

# Create a user for Tomcat to run as
poise_service_user 'tomcat'

# Create an instance folder
['', 'conf', 'webapps', 'temp', 'prevayler'].each do |path|
  directory "/srv/octan_blog/#{path}" do
    owner 'tomcat'
    group 'tomcat'
    mode '755'
  end
end

# Write out Tomcat instance config
template '/srv/octan_blog/conf/server.xml' do
  source 'server.xml.erb'
  owner 'root'
  group 'root'
  mode '644'
end

template '/srv/octan_blog/conf/web.xml' do
  source 'web.xml.erb'
  owner 'root'
  group 'root'
  mode '644'
end

# Deploy the blog application WAR
# This should be coming from a real artifact storage system but because I had to
# patch the provided code, this will have to do for now
cookbook_file '/srv/octan_blog/webapps/ROOT.war' do
  source 'blog.war'
  owner 'root'
  group 'root'
  mode '644'
end

# Runner script to handle HA magic on AWS
template '/srv/octan_blog/run.sh' do
  source 'run.sh.erb'
  owner 'root'
  group 'root'
  mode '755'
  variables prevayler_volume: node.read('octan', 'prevayler_volume'),
            instance_id: node.read('ec2', 'instance_id'),
            region: node.read('ec2', 'placement_availability_zone').to_s.chop
end

# Set up a service
poise_service 'octan_blog' do
  command '/srv/octan_blog/run.sh'
  # The script needs to be able to mount things, it sudo's to tomcat internally
  user 'root'
  directory '/srv/octan_blog'
  environment CATALINA_HOME: '/opt/tomcat', CATALINA_BASE: '/srv/octan_blog'
end


