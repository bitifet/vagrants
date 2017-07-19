PostgreSQL Vagrant Environment
==============================

PostgreSQL server environment.

  * OS: Ubuntu 16.04 LTS
  * PostgreSQL version: 9.6
  * Data storage: Additional LVM Disk.
    - Virtual size: 100GB.
    - Starting volume size: 20GB.
    - Starting real HD usage (vdi size): about 60MB.


Vagrant environment:
--------------------

  * Vagrantfile    - Defines Ubuntu 16.04 LTS with additional 40GB Disk
  * provision.sh   - Vagrant provisioning script (also executes setup.sh).


Regular scripts:
----------------

> Suitable in Vagrant envirnoment or in production.

  * setup.sh       - Upgrade to PostgreSQL 9.6
  * hotStandby.sh  - Configure as Hot-Standby of another server.
  * pgclone.sh     - Allow to instant-clone PostgreSQL clusters on btrfs filesystems.
  
