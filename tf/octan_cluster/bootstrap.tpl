#!/bin/bash

# Set strict mode
set -euo pipefail
IFS=$'\n\t'

# Create the runner script
cat >/usr/local/bin/run-chef <<EOH
#!/bin/bash

# Set strict mode
set -euo pipefail
IFS=$'\n\t'

# Download the policy tarball
if [[ ! -e /var/cache/chef_policy ]]; then
  mkdir /var/cache/chef_policy
fi
curl -o /var/cache/chef_policy/policy.tgz ${chef_policy_url}
tar xzf /var/cache/chef_policy/policy.tgz -C /var/cache/chef_policy

# Run chef
cd /var/cache/chef_policy
chef-client -z
EOH

# Make the runner script executable
chmod u+x /usr/local/bin/run-chef

# Write out extra config for things like service discovery
cat >/etc/octan.json <<EOH
${extra_config}
EOH

# Install Chef
curl -L https://omnitruck.chef.io/install.sh | bash

# Run the runner to kick off bootstrapping
/usr/local/bin/run-chef
