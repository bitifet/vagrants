#!/usr/bin/env bash
echo "=== ===================================================== ==="
echo "=== PostgresSQL as SUPER-Hot-Standby configuration script ==="
echo "=== ===================================================== ==="

STARTING_PORT=6000;
REPLICATION_USER='replication';

# Helper functions:#{{{
# =================

# function help() // Display help message. #{{{
function help() {
local self=$(basename "$0")
local helpCmd=${1};

case "${helpCmd}" in
add)
cat <<!EOF

SYNTAX: ${self} ${helpCmd} pg_version master_host [master_port]

    Assist to create new standby of specified host.

!EOF
;;
list)
cat <<!EOF

SYNTAX: ${self} ${helpCmd}

    List existing clusters (same as pg_lsclusters but less verbose: Just show
    version, name and current status).

!EOF
;;
drop)
cat <<!EOF

SYNTAX: ${self} ${helpCmd} pg_version master_host

    Remove existing (standby) cluster.

!EOF
;;
help)
cat <<!EOF

SYNTAX: ${self} ${helpCmd} [ command ]

    Shows usage details for given command or general usage help if unspecified.

!EOF
;;
*)
cat <<!EOF

USAGE: ${self} <command> [args...]

    Available commands are:

        * help - Show this help message.
        * list - List existing clusters.
        * add  - Create new standby cluster of specified master.
        * drop - Remove existing (standby) cluster.

    Type ${self} help <command> for detailed command usage help.

!EOF
;;
esac;

}
#}}}

# function usageeror() // Generate usage error. #{{{
function usageerror() {
    >&2 echo "SYNTAX ERROR: ${1}";
    >&2 help "${cmd}";
    exit 1;
}
#}}}

# function runtimeerror() // Generate runtime error. #{{{
function runtimeerror() {
    >&2 echo "ERROR ${1}";
    exit 1;
}
#}}}

# function displayMessage()#{{{
function displayMessage() {
    local msg="${1}";
    echo "";
    echo "===========================================================";
    echo "";
    echo "${msg}"
    echo "";
    echo "===========================================================";
    echo "";
}
#}}}

# function askConfirm()#{{{
function askConfirm() {
    local msg="${1}";
    displayMessage "${msg}";

    read -p "Are you FULLY sure (Yes/No)? " answer;
    while [ "${answer}" != yes -a "${answer}" != no ]; do

        echo "...";
        if [ "${answer}" == "no" ]; then
            exit 1;
        elif [ "${answer}" != "yes" ]; then
            read -p "Please answer with 'yes' or 'no': " answer;
        fi;

    done;
}
#}}}

# function checkRoot() // Check root identity. #{{{
function checkRoot() {
    # Make sure only root can run our script
    if [ "$(id -u)" != "0" ]; then
       runtimeerror "This script must be run as root"
    fi
}
#}}}

# function checkVersion() // (Improvable) Check of version parameter. #{{{
function checkVersion() {
    if [[ -z "${pg_version}" ]] ; then
        usageerror "Invalid version number: ${pg_version}" "${cmd}";
    fi;
}
#}}}

# function checkHost() // (Improvable) Check of (remote) host name. #{{{
function checkHost() {
    if [[ -z "${master_host}" ]] ; then
        usageerror "Invalid host name: ${master_host}";
    fi;
}
#}}}

# function checkPort() // (Improvable) Check of (remote) port number. #{{{
function checkPort() {
    re='^[0-9]+$'
    if ! [[ $master_port =~ $re ]] ; then
        usageerror "Invalid port number: ${master_port}";
    fi;
}
#}}}

# function getFreePort() // Get first available port number for new cluster. #{{{
function getFreePort() {
    local lastPort=$(
        (echo $(( ${STARTING_PORT} - 1 )) ; pg_lsclusters -h) \
        | tr -s ' ' \
        | cut -f 3 -d ' ' \
        | sort -nr \
        | head -n 1
    ) 
    echo $(( ${lastPort:-${STARTING_PORT} - 1} + 1 ));
}
#}}}

# function warn_masterSetup()#{{{
function warn_masterSetup() {
    echo ""
    echo "Please, DOUBLE CHECK master setup:"
    echo "----------------------------------"
    echo ""
    echo "  * Both, master and standby PostgreSQL server is of the same version."
    echo ""
    echo "  * Check that '${REPLICATION_USER}' user was propperly created on master:"
    echo "      $ sudo -u postgres createuser ${REPLICATION_USER} -P -c 5 --replication"
    echo ""
    echo "  * Check connectivity to master PostgreSQL port."
    echo ""
    echo "  * Check that '${REPLICATION_USER}' user has REPLICATION privilege in master's pg_hba.conf."
    echo "     | # TYPE  DATABASE     USER         ADDRESS          METHOD |"
    echo "     |   host  replication  ${REPLICATION_USER}  <standby_ip>/32  md5    |"
    echo ""
    echo "  * Check postgresql.conf of the master server:"
    echo "    - wal_level = replica  # (or so...)"
    echo "    - max_wal_senders = 5  # (or so...)"
    echo "    - wal_keep_segments = 32 # (at least, but not necessary if wal-archiving is enabled)."
    echo ""
    echo "  * If you changed any of below settings, reload or restart service in master as needed."
    echo ""
    read -p "Press ENTER if you are ready to continue or CTRL+C to cancel..."
}
#}}}

# function sFetch()#{{{
function sFetch() {
# USAGE: sFetch <localPath> <remoteServer> <remoteFile1> [remoteFile2 ...]

local localPath=$1; shift;
local remoteServer=$1; shift;
local startBanner="#####:: SYSTEM MESSAGE START ::#####"
local endBanner="#####:: SYSTEM MESSAGE END ::#####"
local remoteUser;
local remotePass;
local remoteUrl;

echo ""
echo "______________________________________________________________________________________________"
echo "INFO: We are going to fetch MASTER server configuration files..."
echo "    To do that we need a username and passord with SUDO privileges in the MASTER server."
echo "    Now, you will be asked for them..."
echo "NOTE: This password will be asked twice because ssh always asks it by itself but we need it"
echo "    too to be able to copy needed files thoug sudo."
echo "______________________________________________________________________________________________"

read -p "MASTER sudoed user name: " remoteUser
read -s -p "MASTER sudoed user password: " remotePass
echo ""
echo "______________________________________________________________________________________________"
echo ""
remoteUrl="${remoteUser}@${remoteServer}";
echo "Starting fetching process..."
echo ""
echo "Connecting to MASTER. Remember that user's password will be asked again just now.";
echo ""


function pick() {

    while (( "$#" )); do
        local remoteFile="${1}";
        local localFile="${localPath}/$(basename ${remoteFile})";
        echo "echo cat \> " "\"${localFile}\"" "\<\<!FEOF${#}";
        echo "echo \"${remotePass}\" | 2>/dev/null sudo -S cat \"${remoteFile}\";";
        echo "echo !FEOF${#}";
        echo "";
        shift;
    done
};


(
echo "${startBanner}";
ssh "${remoteUrl}" <<!EOF
echo "${endBanner}"
$(pick ${@});
!EOF
) \
    | sed "/${startBanner}/,/${endBanner}/d" \
    | bash


echo "______________________________________________________________________________________________"
echo "INFO: Config files sucessfully fetched.";
echo "______________________________________________________________________________________________"


}
#}}}

# function mergeFile()#{{{
function mergeFile() {
    
    local oldFile="${1}";
    local newFile="${2}";
    local mergedFile="${3}";
    local acceptOld=${4};
    local acceptNew=${5};

    local fName=$(basename "${mergedFile}");

    function fixFile() {
        echo "Failed to automatically merge ${fileName}"
        read -p "Press ENTER to edit and manually fix conflicts or CTRL+C to cancel..."
        vim "${mergedFile}";
    };

    humandiff -i \
        -o "${acceptOld}" \
        -n "${acceptNew}" \
        "${oldFile}" \
        "${newFile}" \
        "Proposed / Default (Standby)" \
        "Master" \
    > "${mergedFile}";

    local exitCode=$?;
    if [ $exitCode -eq 1 ]; then
        fixFile;
        exitCode=$?;
    fi;
    if [ $exitCode -ne 0 ]; then
        runtimeerror "Failed to merge ${fName} file."
    fi;

}
#}}}

# function mergePostgresqlConf()#{{{
function mergePostgresqlConf() {
    
    local oldFile="${1}";
    local newFile="${2}";
    local mergedFile="${3}";

    local acceptOld=$(
        echo "
            data_directory
            hba_file
            ident_file
            external_pid_file
            port
            shared_buffers
            wal_level
            max_wal_senders
            wal_keep_segments
            cluster_name
            stats_temp_directory
        " \
        | xargs \
        | sed 's/ /,/g' \
    );

    local acceptNew=$(
        echo "
            listen_addresses
            max_connections
            log_timezone
            datestyle
            timezone
            lc_messages
            lc_monetary
            lc_numeric
            lc_time
            default_text_search_config
        " \
        | xargs \
        | sed 's/ /,/g' \
    );

    mergeFile \
        "${oldFile}" \
        "${newFile}" \
        "${mergedFile}" \
        "${acceptOld}" \
        "${acceptNew}" \
    ;


}
#}}}

# function mergePghbaConf()#{{{
function mergePghbaConf() {
    
    local oldFile="${1}";
    local newFile="${2}";
    local mergedFile="${3}";

    local acceptOld=$(
        echo "
            replication
        " \
        | xargs \
        | sed 's/ /,/g' \
    );

    local acceptNew=$(
        echo "
            bar
        " \
        | xargs \
        | sed 's/ /,/g' \
    );



    mergeFile \
        "${oldFile}" \
        "${newFile}" \
        "${mergedFile}" \
        "${acceptOld}" \
        "${acceptNew}" \
    ;

}
#}}}

# function configureHotStandby()#{{{
function configureHotStandby() {
local configFile="${1}";

cat >> "${configFile}" <<!HSconfigEOF


###########################################
# Hot-Standby configuration section       #
# --------------------------------------- #

# Allow read queries during recovery:
# (Hot Standby mode)
hot_standby = on

###########################################

!HSconfigEOF

};
#}}}

# function config_setup()#{{{
function config_setup() {

    local templatesPath="${pg_local_cfgPath}/multistandby";

    local masterConfPath="${templatesPath}/postgresql.master.conf";
    local masterHbaPath="${templatesPath}/pg_hba.master.conf";
    local baseConfPath="${templatesPath}/postgresql.base.conf";
    local baseHbaPath="${templatesPath}/pg_hba.base.conf";

    local realConfPath="${pg_local_cfgPath}/postgresql.conf";
    local realHbaPath="${pg_local_cfgPath}/pg_hba.conf";

    # Fetch files:
    mkdir "${templatesPath}";
    sFetch \
        "${templatesPath}" \
        "${master_host}" \
        "${pg_remote_cfgPath}/postgresql.conf" \
        "${pg_remote_cfgPath}/pg_hba.conf"\
    ;

    # Move things:
    mv "${templatesPath}/postgresql.conf" "${masterConfPath}";
    mv "${templatesPath}/pg_hba.conf" "${masterHbaPath}";
    mv "${realConfPath}" "${baseConfPath}";
    mv "${realHbaPath}" "${baseHbaPath}";

    # Configure things:
    configureHotStandby "${baseConfPath}";

    # Merge things:
    mergePostgresqlConf "${baseConfPath}" "${masterConfPath}" "${realConfPath}";
    mergePghbaConf "${baseHbaPath}" "${masterHbaPath}" "${realHbaPath}";

}
#}}}

# =================#}}}


# Commands:#{{{
# =========

# function cmdList() // List existing clusters. #{{{
function cmdList() {
    pg_lsclusters | perl -pe 's/(^\S+\s+\S+\s+\S+\s+\S+).*/$1/'
}
#}}}

# function cmdAdd()#{{{
function cmdAdd() {

    pg_basePath="/var/lib/postgresql"
    pg_clusterPath="${pg_basePath}/${pg_version}/${master_host}"

    pg_remote_cfgPath="/etc/postgresql/${pg_version}/main"
    pg_local_cfgPath="/etc/postgresql/${pg_version}/${master_host}"

    checkRoot;
    checkVersion;
    checkHost;
    checkPort;

    warn_masterSetup;

    # Create cluster:
    echo "Creating new target cluster..."
    pg_createcluster --port "${local_pg_port}" "${pg_version}" "${master_host}" \
        || runtimeerror "Failed to create new cluster"

    # Erase contents:
    echo "Erasing cluster contents..."
    sudo rm -rf "${pg_clusterPath}" \
        || runtimeerror "Failed to erase cluster contents"

    sudo mkdir "${pg_clusterPath}"
    sudo chown postgres:postgres "${pg_clusterPath}"
    sudo chmod 700 "${pg_clusterPath}"


    displayMessage "Configure Standby";

    config_setup;


    displayMessage "Fetch Base Backup from Master";

    echo ""
    echo "Retriving base backup from master..."
    echo "Please, provide password for ${REPLICATION_USER} PostgreSQL user on ${master_host}..."
    sudo -u postgres pg_basebackup -h "${master_host}" -p ${master_port} -D "${pg_clusterPath}" -P -U "${REPLICATION_USER}" --xlog-method=stream -R


    displayMessage "Starting Up..."
    echo "Please wait..."

    pg_ctlcluster "${pg_version}" "${master_host}" start

    displayMessage "DONE!!"

    cmdList;

}
#}}}

# function cmdDrop()
function cmdDrop() {
    checkRoot;
    checkVersion;
    checkHost;

    pg_dropcluster "${pg_version}" "${master_host}" --stop

};


# =========#}}}


cmd="${1}";

case "${cmd}" in
    list)
        cmdList;
        ;;
    add)
        pg_version=$2;
        master_host=$3;
        master_port=${4:-5432};
        local_pg_port="$(getFreePort)";
        cmdAdd;
        ;;
    drop)
        pg_version=$2;
        master_host=$3;
        askConfirm "You are going to remove Hot Standby for ${pg_version} ${master_host}";
        cmdDrop;
        ;;
    help)
        help "${2}";
        ;;
    *)
        usageerror "Unknown command: ${cmd}";
        ;;
esac;




exit;











