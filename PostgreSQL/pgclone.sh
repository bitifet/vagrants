#!/usr/bin/env bash

# SETUP EXAMPLE:
# --------------
# 
# # Install btrfs-tools:
# sudo apt-get install btrfs-tools
# 
# # Create btrfs filesystem across one or more divices:
# #   -> Check device names!!
# sudo mkfs.btrfs -L pgCluster /dev/sdb /dev/sdc /dev/sdd
#
# # Stop postgresql cluster:
# sudo /etc/init.d/postgresql stop
# 
# # Preserve (move) cluster data aside:
# sudo mv /var/lib/postgresql /var/lib/postgresql_old
# 
# # Create mount point:
# sudo mkdir /var/lib/postgresql
# sudo chown postgres:postgres /var/lib/postgresql
# 
# # Configure fstab and mount:
# sudo bash -c 'echo "/dev/sdb        /var/lib/postgresql   btrfs   defaults 0       0" >> /etc/fstab'
# sudo mount -a 
#
# # Move back data to it's original location:
# sudo mv /var/lib/postgresql_old/* /var/lib/postgresql/
# sudo mv /var/lib/postgresql_old/.psql_history /var/lib/postgresql
# ## FIXME: Move databases infividually by previously creating subvolume per each.
#
# # Restart database:
# sudo /etc/init.d/postgresql start
#
# # Drop backup:
# sudo rmdir /var/lib/postgresql_old/



function help {
cmd=$(basename $0);
cat <<!EOF

USAGE:

    ${cmd} create dbName
        - Creates new db and moves it to subvolume.
    ${cmd} snapshot srcDb destDb
        - Creates snapshot of srcDb as destDb.
    ${cmd} drop dbName
        - Drop db and propperly removes its subvolume.
    ${cmd} [-h]
        - Shows this help message.


!EOF
};

#function create_db {{{
function create_db {

export dbName="$1";

sudo su <<!EOF

sudo -u postgres createdb "${dbName}";
dbOID=\$(echo "select oid from pg_database where datname = '${dbName}';" | sudo -u postgres psql -t | xargs)

clusterPath=\$(echo "show data_directory;" | sudo -u postgres psql -t | xargs)
sudo /etc/init.d/postgresql stop

dbPath="\${clusterPath}/base/\${dbOID}";

mv "\${dbPath}" "\${dbPath}_orig"
btrfs subvolume create "\${dbPath}"
chown postgres:postgres "\${dbPath}/"

cp -a "\${dbPath}_orig/"* "\${dbPath}/"
rm -rf "\${dbPath}_orig"


sudo /etc/init.d/postgresql start


!EOF
};
#}}}

#function snapshotdb {{{
function snapshotdb {

export srcDB="$1";
export dstDB="$2";

sudo su <<!EOF

srcOID=\$(echo "select oid from pg_database where datname = '${srcDB}';" | sudo -u postgres psql -t | xargs)
sudo -u postgres createdb "${dstDB}";
dstOID=\$(echo "select oid from pg_database where datname = '${dstDB}';" | sudo -u postgres psql -t | xargs)

clusterPath=\$(echo "show data_directory;" | sudo -u postgres psql -t | xargs)
sudo /etc/init.d/postgresql stop

srcPath="\${clusterPath}/base/\${srcOID}";
dstPath="\${clusterPath}/base/\${dstOID}";

rm -rf "\${dstPath}";
btrfs subvolume snapshot "\${srcPath}" "\${dstPath}" 2>/dev/null || (
    echo "Migrating \${srcPath} to btrfs subvolume...";
    echo "  * Renaming \${srcPath}" to "\${srcPath}_orig"
    mv "\${srcPath}" "\${srcPath}_orig"
    echo "..."
    btrfs subvolume create "\${srcPath}";
    echo "..."
    chown postgres:postgres "\${srcPath}";
    echo "..."
    cp -a "\${srcPath}_orig/"* "\${srcPath}/"
    echo "..."
    btrfs subvolume snapshot "\${srcPath}" "\${dstPath}"
    echo "..."
    rm -rf "\${srcPath}_orig"
)


sudo /etc/init.d/postgresql start


!EOF
};
#}}}

#function drop_db {{{
function drop_db {

export dbName="$1";

sudo su <<!EOF

dbOID=\$(echo "select oid from pg_database where datname = '${dbName}';" | sudo -u postgres psql -t | xargs)


clusterPath=\$(echo "show data_directory;" | sudo -u postgres psql -t | xargs)
dbPath="\${clusterPath}/base/\${dbOID}";


echo "Dropping database..."
echo "INFO: Database will say that couldn't remove \"base/${dbOID}\"."
echo "  ...this is ABSOLUTELY NORMAL becauese it is'nt a direcctory but btrfs subvolume."
echo "  ...we will properly remove just after."
echo ""
sudo -u postgres dropdb "${dbName}";

echo "Deleting subvolume..." 
btrfs subvolume delete "\${dbPath}"



!EOF
};
#}}}

case $1 in
    "snapshot" )
        snapshotdb $2 $3;
        exit;
    ;;
    "create" )
        create_db $2;
        exit;
    ;;
    "drop" )
        drop_db $2;
        exit;
    ;;
    * )
        help $0

    ;;
esac;


