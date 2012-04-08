#!/bin/bash

######################################################################
#
# This runs as root on the server
#
######################################################################

rubyversion=1.9.3-p125
rubydir=/usr/local
rubybindir=$rubydir/bin
gembinary=$rubybindir/gem
rubybinary=$rubybindir/ruby
chefbinary=$rubybindir/chef-solo
knifebinary=$rubybindir/knife
http_proxy=http://192.168.33.13:8000/

######################################################################
# Remove Vagrant ruby
######################################################################
remove_vagrant_ruby()
{
  # Vagrant hack
  if [ -d /opt/ruby ]
  then
    rm -rf /opt/ruby
  fi
}

######################################################################
# Setup proxy
######################################################################
setup_proxy()
{
  local http_proxy=$1

  if [ -n $http_proxy ]
  then
    echo "Acquire::http::Proxy \"$http_proxy\";" > /etc/apt/apt.conf.d/cache
  fi
}

######################################################################
# Update base OS
######################################################################
update_base_os()
{
  # Upgrade headlessly (this is only safe-ish on vanilla systems)
  # aptitude update &&
  # apt-get -o dpkg::options::="--force-confnew" \
  #     --force-yes -fuy dist-upgrade &&

  apt-get update
}

######################################################################
# Install ruby
######################################################################
install_ruby()
{
  local rubyversion=$1
  local rubydir=$2
  local rubybinary=$3
  if [ ! -f /usr/local/bin/ruby-build ]
  then
    mkdir /root/ruby-build
    wget -q -O- "https://github.com/sstephenson/ruby-build/tarball/master" | tar -z -x -C/root/ruby-build --strip-components 1
    cd /root/ruby-build
    /root/ruby-build/install.sh
    cd /root
    rm -r /root/ruby-build
  fi

  if [ ! -f $rubybinary ]
  then
    # Install development tools:
    apt-get -y install build-essential curl

    # Extras for RubyGems and Rails:
    apt-get -y install zlib1g-dev libssl-dev

    # Readline Dev on Ubuntu 10.04 LTS:
    apt-get -y install libreadline5-dev

    echo /usr/local/bin/ruby-build $rubyversion $rubydir
    /usr/local/bin/ruby-build $rubyversion $rubydir
  fi
}

######################################################################
# Install chef
######################################################################
install_chef()
{
  local gembinary=$1
  command -v chef-solo >/dev/null 2>&1 || $gembinary install --no-rdoc --no-ri chef
}

######################################################################
# Configure chef
######################################################################
configure_chef()
{
  mkdir -p /etc/chef
  echo "file_cache_path \"/tmp/chef-solo\"" > /etc/chef/solo.rb
  echo "cookbook_path \"/tmp/chef-solo/cookbooks\"" >> /etc/chef/solo.rb

  echo '{
  "chef_server": {
    "server_url": "http://localhost:4000",
    "webui_enabled": true,
    "init_style": "runit"
  },
  "run_list": [ "recipe[chef-server::rubygems-install]" ]
}' > ~/chef.json
}

######################################################################
# Run chef
######################################################################
run_chef()
{
  local chefbinary=$1
  $chefbinary -c /etc/chef/solo.rb -j ~/chef.json -r http://s3.amazonaws.com/chef-solo/bootstrap-latest.tar.gz
}

######################################################################
# Create chef admin user
######################################################################
create_admin_chef_user()
{
  local knifebinary=$1
  $knifebinary configure -i --defaults -u admin -r ''
}

setup_chef()
{
  local gembinary=$1
  local chefbinary=$2
  install_chef $gembinary
  configure_chef
  run_chef $chefbinary

  # Hack: Sleep 2 to ensure certificates have been generated
  sleep 2

  create_admin_chef_user $knifebinary
}
export DEBIAN_FRONTEND=noninteractive
remove_vagrant_ruby
setup_proxy $http_proxy
update_base_os
install_ruby $rubyversion $rubydir $rubybinary
setup_chef $gembinary $chefbinary

echo "Done"
