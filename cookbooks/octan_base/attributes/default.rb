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

# Baseline of ensuring the key exists
default['octan'] = {}

# Load the bootstrap-seeded config
if File.exist?('/etc/octan.json')
  data = Chef::JSONCompat.parse(IO.read('/etc/octan.json'))
  default['octan'].update(data)
end

# Settings for the sudo cookbook
default['authorization']['sudo']['include_sudoers_d'] = true
