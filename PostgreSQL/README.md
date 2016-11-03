PostgreSQL Vagrant Environment
==============================

PostgreSQL server environment.


Vagrant environment:
--------------------

  * Vagrantfile    - Defines Ubuntu 16.04 LTS with additional 40GB Disk
  * provision.sh   - Vagrant provisioning script (also executes setup.sh).


Regular scripts:
----------------

> Suitable in Vagrant envirnoment or in production.

  * setup.sh       - Upgrade to PostgreSQL 9.6
  * hotStandby.sh  - Configure as Hot-Standby of another server.
  
