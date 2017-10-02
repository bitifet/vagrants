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
  * provision.sh   - Vagrant provisioning script (also executes setup.sh).


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


<a name="multiStandby"></a>
### `multiStandby.sh`

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


#### Setup

  1. Place multiStandby.sh script somwhere (preferrable under directory present
in $PATH.

  2. Install [humandiff](https://www.npmjs.com/package/humandiff) (you need nodeJS and npm already installed): `sudo npm install -g humandiff`

  3. Install all PostgreSQL-server versions you need to hold (most of relatively recent versions will be available as .deb packages on ubuntu/debian disros). Example:


    $ sudo apt-get install postgresql-9.6 \
                           postgresql-9.5 \
                           postgresql-9.4 \
                           postgresql-9.3

  4. Remove clusters created by default (except if you plan to use it as regular databases). Example:


    $ sudo pg_dropcluster 9.6 main
    $ sudo pg_dropcluster 9.5 main
    $ sudo pg_dropcluster 9.4 main
    $ sudo pg_dropcluster 9.3 main


#### Usage


    USAGE: multiStandby.sh <command> [args...]

        Available commands are:

            * help - Show this help message.
            * list - List existing clusters.
            * add  - Create new standby cluster of specified master.
            * drop - Remove existing (standby) cluster.

        Type multiStandby.sh help <command> for detailed command usage help.


#### Example:

    ubuntu@multiStandbyServer:~$ sudo ./multiStandby.sh list
    === ===================================================== ===
    === PostgresSQL as SUPER-Hot-Standby configuration script ===
    === ===================================================== ===
    Ver Cluster                Port Status
    9.6 alfrescoServer         6001 online,recovery
    9.5 daedalus.example.com   6002 online,recovery
    9.6 someServer             6000 online,recovery



<a name="pgClone"></a>
### `pgclone.sh`

Allow to instant-clone PostgreSQL clusters on btrfs filesystems.


