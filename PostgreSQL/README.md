PostgreSQL Vagrant Environment
==============================

PostgreSQL server environment.

  * OS: Ubuntu 16.04 LTS
  * PostgreSQL version: 9.6
  * Data storage: Additional LVM Disk.
    - Virtual size: 100GB.
    - Starting volume size: 20GB.
    - Starting real HD usage (vdi size): about 60MB.


<a name="vagrant"></a>
Vagrant environment:
--------------------

  * Vagrantfile    - Defines Ubuntu 16.04 LTS with additional 40GB Disk
  * provision.sh   - Vagrant provisioning script (also executes `setup.sh --vagrant`).


<a name="scripts"></a>
Regular scripts:
----------------

Suitable in Vagrant envirnoment or in production.


<a name="setup"></a>
### `setup.sh`

Upgrade to PostgreSQL 9.6


<a name="hotStandby"></a>
### `hotStandby.sh`

Configure as Hot-Standby of another server.


<a name="pgstandby"></a>
### `pgstandby`

Helps to easily manage multiple HotStandby clusters in the same server.

  * Based on `hostStandby.sh`.

  * Unlike in `hotStandby.sh`, some master parameters are assumed:

    - Replication user is supposed to be 'replication'.
    - Cluster name is supposed to be 'main'.
    - Port is by default 5432 (even can be specified in command-line).

  * Also, some standby parameters are assumed:

    - Port is automatically assigned (sequentially, starting from 6000).
    - Master host name is used as Standby cluster name.

  * Multiple PostgreSQL versions can be handled in the same server:

  * Automatically configures hot-standby cluster:

    - Uses default configuration files (created by pg_createcluster command).
    - Perform required modifications to put it in hot-standby mode.
    - Fetch and merge-in master configuration files so some special parameters
      (specially memory-related ones) are automatically imported. 
    - Other differnces (specially pg_hba.conf accesses) require manual review
      so you can decide to respect them (for example to allow same accesses in
      case of failover) or restrict some (like replication user itself) or all
      of them.
    - **IMPORTANT:** This requires
      [humandiff](https://www.npmjs.com/package/humandiff) to easily merge
      master and default hot-standby configuration files (postgresql.conf and
      hba.conf).

**WARNING:** This documentation is not fully updated. See own script help info
for more accurated documentation.

#### Setup

  1. Place pgstandby script somwhere, preferrable under directory present
in $PATH (/usr/local/bin for example).

  2. Edit it and customize 'Global parameters' secion (if needed).

  3. Install [humandiff](https://www.npmjs.com/package/humandiff) (you need
     nodeJS and npm already installed): `sudo npm install -g humandiff`

  4. Install all PostgreSQL-server versions you need to hold (most of
     relatively recent versions will be available as .deb packages on
     ubuntu/debian disros). Example:


    $ sudo apt-get install postgresql-9.6 \
                           postgresql-9.5 \
                           postgresql-9.4

  4. Remove clusters created by default (except if you plan to use it as
     regular databases). Example:


    $ sudo pg_dropcluster 9.6 main
    $ sudo pg_dropcluster 9.5 main
    $ sudo pg_dropcluster 9.4 main


#### Usage



    $ pgstandby help
    === ===================================================== ===
    === PostgresSQL as SUPER-Hot-Standby configuration script ===
    === ===================================================== ===

    SYNOPSIS
        pgstandby [modifiers] <command> [args...]

    MODIFIERS
        --silent Supress normal output unless warning or error is triggered.
        --log    Save output to log file (even in silent mode).

    COMMANDS
        help    - Show this help message.
        list    - List existing clusters.
        check   - Check standby clusters status.
        add     - Create new standby cluster of specified master.
        drop    - Remove existing (standby) cluster.
        clone   - Create (writable) copy of (master or standby) cluster.
        viconf  - postgresql.conf edit helper.
        vihba   - hba.conf edit helper.
        start   - Cluster start helper.
        stop    - Cluster reload helper.
        reload  - Cluster reload helper.
        restart - Cluster restart helper.
        log     - Cluster log inspection helper.
        backup  - Backup tool.
        stream  - wal/xlog streaming service

    NOT YET IMPLEMENTED...
        restore - PITR Restore backup tool.

    HINT
        Type 'pgstandby help <command>' for detailed command usage help.



#### Example:


    $ pgstandby list
    This script must be run as root...
    [sudo] password for myUser:
    === ===================================================== ===
    === PostgresSQL as SUPER-Hot-Standby configuration script ===
    === ===================================================== ===
    Ver Cluster                 Port Status           Standby  Backup
    -----------------------------------------------------------------
    9.4 server1.example.com     6001 online,recovery  conErr   ONLINE
    9.4 server2.example.com     6002 offline,recovery OFFLINE  conErr
    9.6 server3.example.com     6007 online,recovery  ONLINE   ONLINE
    TOTAL:  3



<a name="pgClone"></a>
### `pgclone.sh`

Allow to instant-clone PostgreSQL clusters on btrfs filesystems.


