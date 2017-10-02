#!/usr/bin/env bash

echo "=== =============================================== ==="
echo "=== PostgresSQL as Hot-Standby configuration script ==="
echo "=== =============================================== ==="


echo ""
echo "Please, DOUBLE CHECK master setup:"
echo "----------------------------------"
echo ""
echo "  * Both, master and standby PostgreSQL server is of the same version."
echo ""
echo "  * Check that 'replication' user was propperly created on master:"
echo "      $ sudo -u postgres createuser replication -P -c 5 --replication"
echo ""
echo "  * Check connectivity to master PostgreSQL port."
echo ""
echo "  * Check that 'replication' user has REPLICATION privilege in master's pg_hba.conf."
echo "     | # TYPE  DATABASE     USER         ADDRESS          METHOD |"
echo "     |   host  replication  replication  <standby_ip>/32  md5    |"
echo ""
echo "  * Check postgresql.conf of the master server:"
echo "    - wal_level = replica  # (or so...)"
echo "    - max_wal_senders = 5  # (or so...)"
echo "    - wal_keep_segments = 32 # (at least, but not necessary if wal-archiving is enabled)."
echo ""
echo "  * If you changed any of below settings, reload or restart service in master as needed."
echo ""
read -p "Press ENTER if you are ready to continue or CTRL+C to cancel..."


echo ""
echo ""
echo ""
echo "Please, DOUBLE CHECK standby setup:"
echo "-----------------------------------"
echo ""
echo "  * PostgreSQL server of the same version as master is installed."
echo ""
echo "  * There is an EMPTY enabled cluster to be used (WARNING: Existing data will be dropped)"
echo ""
echo "  * PostgreSQL server is stopped. If not stop it:"
echo "      $ sudo /etc/init.d/postgresql stop"
echo ""
read -p "Press ENTER if you are ready to continue or CTRL+C to cancel..."



echo ""
echo ""
echo ""
echo "Please, provide required data:"
echo "------------------------------"
echo ""

read -p "MASTER PostgreSQL name or IP: " pg_remote_addr

read -p "MASTER PostgreSQL port (Default: 5432): " pg_remote_port
pg_remote_port=${pg_remote_port:-5432}

read -p "MASTER replication-enabled PostgreSQL user name (Default: replication): " pg_repl_user
pg_repl_user=${pg_repl_user:-replication}

echo ""
echo "______________________________________________________________________________________________"
echo "INFO: We will copy MASTER's postgresql.conf and pg_hba.conf for you as a base configuration..."
echo "To do that we need a username and passord with SUDO privileges in the MASTER server."
echo "Now, you will be asked ONCE for them..."
echo "NOTE: This password is asked ONLY to be used with remote sudo commands. You will be asked for"
echo "it anyway in every ssh connection because ssh always asks it by itself."
echo "______________________________________________________________________________________________"

read -p "MASTER sudoed user name: " master_username
read -s -p "MASTER sudoed user password: " master_userpass
echo ""
echo "______________________________________________________________________________________________"
echo ""

pg_def_version=$(psql --version | perl -pe 's/.*?(\d+\.\d+).*/$1/') 2>/dev/null
read -p "PostgreSQL version (Default: ${pg_def_version}): " pg_version
pg_version=${pg_version:-${pg_def_version}}

read -p "PostgreSQL destination cluster name (Default: main): " pg_cluster_name
pg_cluster_name=${pg_cluster_name:-main}

pg_default_cluster_path="/var/lib/postgresql/${pg_version}/${pg_cluster_name}"
read -p "STANDBY (local) destination cluster path (Default: ${pg_default_cluster_path}): " pg_cluster_path
pg_cluster_path=${pg_cluster_path:-${pg_default_cluster_path}}


pg_default_remote_cfgpath="/etc/postgresql/${pg_version}/main";
read -p "Please, provide MASTER PostgreSQL configuration path (Default ${pg_default_remote_cfgpath}): " pg_remote_cfgpath
pg_remote_cfgpath=${pg_remote_cfgpath:-${pg_default_remote_cfgpath}}

pg_default_local_cfgpath="/etc/postgresql/${pg_version}/${pg_cluster_name}";
read -p "Please, provide STANDBY PostgreSQL configuration path (Default ${pg_default_local_cfgpath}): " pg_local_cfgpath
pg_local_cfgpath=${pg_local_cfgpath:-${pg_default_local_cfgpath}}



echo ""
echo ""
echo ""
echo "Starting STANDBY Configuration Process:"
echo "---------------------------------------"
echo ""

read -p "WARNING: We are going to remove ALL cluster contents on ${pg_cluster_path}. (CTRL+C to Cancel)"

echo ""
echo "Removing cluster data..."
sudo rm -rf "${pg_cluster_path}"
sudo mkdir "${pg_cluster_path}"

echo ""
echo "Ensuring propper ownereship..."
sudo chown postgres:postgres "${pg_cluster_path}"

echo ""
echo "Retriving configuration from master..."
echo "  * Copying postgresql.conf..."
(
    echo $master_userpass | ssh "${master_username}@${pg_remote_addr}" "sudo -S cat '${pg_remote_cfgpath}/postgresql.conf'" \
    && echo "hot_standby = on"
) \
    | perl -pe 's/^(\s*archive_mode\s*=.*)/#$1/i' \
    | perl -pe 's/^(\s*wal_level\s*=.*)/#$1/i' \
    | perl -pe 's/^(\s*max_wal_senders\s*=.*)/#$1/i' \
    | perl -pe "s#^(\\s*data_directory\\s*=\\s*)'.*?'#\$1'${pg_cluster_path}'#i" \
    | perl -pe "s#${pg_remote_cfgpath}#${pg_local_cfgpath}#i" \
    | sudo tee "${pg_local_cfgpath}/postgresql.conf" > /dev/null
    # Reset archive_mode
    # Reset wal_level
    # Reset max_wal_senders
    # Fix data_directory
    # Fix config path.
    # Overwrite local file.

echo "  * Copying pg_hba.conf..."
echo $master_userpass | ssh "${master_username}@${pg_remote_addr}" "sudo -S cat '${pg_remote_cfgpath}/pg_hba.conf'" \
    | sudo tee "${pg_local_cfgpath}/pg_hba.conf" > /dev/null
    # Overwrite local file.


echo ""
echo "Retriving base backup from master..."
echo "Please, provide password for ${pg_repl_user} PostgreSQL user on ${pg_remote_addr}..."
sudo -u postgres pg_basebackup -h "${pg_remote_addr}" -p ${pg_remote_port} -D "${pg_cluster_path}" -P -U "${pg_repl_user}" --xlog-method=stream -R

echo ""
echo ""
echo ""
echo "Please, DOUBLE CHECK standby configuration:"
echo "-------------------------------------------"
echo ""

read -p "Press ENTER to edit ${pg_local_cfgpath}/postgresql.conf or CTRL+C to cancel..."
sudo "${EDITOR:-vi}" "${pg_local_cfgpath}/postgresql.conf"

read -p "Press ENTER to edit ${pg_local_cfgpath}/pg_hba.conf or CTRL+C to cancel..."
sudo "${EDITOR:-vi}" "${pg_local_cfgpath}/pg_hba.conf"



echo "===================="
echo "¡¡¡ READY TO GO !!!!"
echo "===================="
echo "Your new StandBy database is ready to be started."




