#!/usr/bin/env bash

# Redirect stderr to stdout when used as vagrant provisioning script:
if [[ "${1}" == "--vagrant" ]]; then
    2>&1 "${0}" --upgrade;
    exit $?;
fi;


# Labeling infrastructure:
function title {
    if 2>/dev/null hash toilet ; then
        toilet -f future "$*";
    else
        echo -e "\e[1m${*}\e[0m";
    fi
}


CODENAME=$(lsb_release -c | awk '{print $2}')
APT_SOURCE="deb http://apt.postgresql.org/pub/repos/apt/ ${CODENAME}-pgdg main"
APT_FILE="/etc/apt/sources.list.d/pgdg.list"


title "Config postgres repository:"

echo Add postgres repository...
echo "${APT_SOURCE}" | sudo tee "${APT_FILE}"

echo Import repository key...
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
      sudo apt-key add -

echo Update package list...
sudo apt-get update


if [[ "${1}" == "--upgrade" ]]; then
    title "Upgrading distro first..."
    sudo apt-get -y dist-upgrade
fi;

LATEST=$( \
    apt-cache search '^postgresql-[0-9]+\.[0-9]+$' \
    | sort -nr \
    | head -n 1 \
    | awk '{print $1}' \
    | perl -pe 's/.*-//' \
);


title Install PostgreSQL-${LATEST} cluster:

sudo apt-get -y install \
    postgresql-${LATEST} \
    postgresql-contrib-${LATEST} \
    htop \
    iotop \
    pg-activity \
;

