#!/usr/bin/env bash

# Labeling infrastructure:
##########################
2>&1 sudo apt-get -y install toilet
function log {
    toilet -f future "$*"
}


log "Upgrade distro (latest LTS):"
################################
2>&1 sudo apt-get update
2>&1 sudo apt-get -y dist-upgrade


log Config postgres repository:
###############################
echo NOTE: This is for PostgreSQL 9.6.0 in ubuntu xenial \(16.04\).
echo See https://www.postgresql.org/download/linux/ubuntu/ for other setups.

echo Add postgres repository...
echo "deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main" \
    | sudo tee /etc/apt/sources.list.d/pgdg.list

echo Import repository key...
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
      sudo apt-key add -

echo Update package list again...
2>&1 sudo apt-get update 


log Install postgres cluster:
#############################
2>&1 sudo apt-get -y install postgresql-9.6 postgresql-contrib-9.6 htop iotop pg_access





