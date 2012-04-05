#!/bin/bash

# This runs as root on the server

chef_binary=/var/lib/gems/1.9.1/bin/chef-solo
serveradminpassword=asdf

# Are we on a vanilla system?
if ! test -f "$chef_binary"
then
    export DEBIAN_FRONTEND=noninteractive
    # Upgrade headlessly (this is only safe-ish on vanilla systems)
    aptitude update &&
    apt-get -o Dpkg::Options::="--force-confnew" \
        --force-yes -fuy dist-upgrade &&
    apt-get -y install build-essential openssl libreadline6 libreadline6-dev curl \
      git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 \
      libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool \
      bison subversion

    if [ -z "$(grep sshlogin /etc/group)" ]
    then
      groupadd sshlogin
    fi

    if [ -z "$(getent passwd serveradmin)" ]
    then
      adduser serveradmin --gecos ",,," --disabled-password
      adduser serveradmin sudo
      adduser serveradmin sshlogin
      echo serveradmin:$serveradminpassword | chpasswd
    fi

    # echo "AllowGroups sshlogin" >> /etc/ssh/sshd_config
    service ssh restart

    # Install Ruby and Chef
    # aptitude install -y ruby1.8 ruby1.8-dev make &&
    # gem install --no-rdoc --no-ri chef --version 0.10.8

    # sudo -u serveradmin -H bash serveradmin-install.sh
fi

# if ! test -f "/usr/local/rvm"
# then
#   bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)
# fi

# "$chef_binary" -c solo.rb -j solo.json
echo "Done"
