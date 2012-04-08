#!/bin/sh
#
# This script can setup a knife client on a local machine if you have ssh
# access to the chef server.
#

host=$1
user=$2
newuser=$3
repodir=`pwd`
chefdir=`pwd`/.chef

if [[ ! -n $1 || ! -n $2 || ! -n $3 ]]
then
  echo "Usage: ./add-knife-client.sh [host] [user] [newuser]"
  exit 1
fi

if [ ! -d $repodir/cookbooks ]
then
  echo "You seem to not be in a chef-repo."
  echo "Please switch to a chef repo and try again."
  exit 2
fi

mkdir .chef

ssh $user@$host "sudo -H EDITOR=cat knife client create $newuser -n -a -f /tmp/$newuser.pem"
scp $user@$host:/tmp/$newuser.pem .chef
ssh $user@$host "sudo rm /tmp/$newuser.pem"

ssh -q $user@$host 'sudo cat /etc/chef/validation.pem' > .chef/validation.pem

cat > .chef/knife.rb <<EOT
log_level                :info
log_location             STDOUT
node_name                '$newuser'
client_key               '$chefdir/$newuser.pem'
validation_client_name   'chef-validator'
validation_key           '$chefdir/validation.pem'
chef_server_url          'http://$host:4000'
cache_type               'BasicFile'
cache_options( :path => '$chefdir/.chef/checksums' )
cookbook_path [ '$repodir/cookbooks' ]
EOT
