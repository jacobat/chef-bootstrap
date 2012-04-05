#!/bin/bash

# Usage: ./deploy.sh [host] [user]

host=$1
user=$2

if [[ ! -n $1 || ! -n $2 ]]
then
  echo "Usage: ./deploy.sh [host] [user]"
  exit 1
fi

# The host key might change when we instantiate a new VM, so
# we remove (-R) the old host key from known_hosts
ssh-keygen -R "${host#*@}" 2> /dev/null

tar c . | ssh -o 'StrictHostKeyChecking no' "$user@$host" '
sudo rm -rf ~/chef &&
  mkdir ~/chef &&
  cd ~/chef &&
  tar x &&
  sudo bash install.sh'
