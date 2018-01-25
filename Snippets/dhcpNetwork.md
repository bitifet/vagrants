dhcp Network
============

Smart bridged networking configuration snippet.

  * Automatically generated random private MAC address.
    - Persistent over `vagrant destroy` so DHCP leases are preserved.
    - Based on (symlink aware) `Vagrantfile` inode number.
    - ...so you can copy or symlink your Vagrantfile getting **different**
      persistent MAC address and IP lease.
 
  * Automatic (and mostly correct) network device detection.
    - Get first enabled non-loopback interface.


Files
-----

### Vagrantfile


    require 'digest'

    [...]

    config.vm.network "public_network",
        use_dhcp_assigned_default_route: true,
        :mac => "02"+String(Digest::MD5.hexdigest `ls -1 -i #{__FILE__}`).slice(1, 10),
        :bridge => `ip link list | grep -viE 'link|loopback' | grep -E '\\bstate UP\\b' | head -n 1 | perl -pe 's/^.*?\\s(\\S*):.*\n$/$1/'`



