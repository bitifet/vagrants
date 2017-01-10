Additional Disk Image
=====================

Sample parameters
-----------------

|||
|----------------------:|-------------------------|
| **FileName:**         | data_disk.vdi           |
| **Max. Size:**        | 400GB                   |
| **Initial Size:**     | 40GB (360GB of PE free) |
| **FileSystem:**       | ext4                    |
| **MountPoint:**       | /data                   |


Files
-----

### Vagrantfile

    config.vm.provider "virtualbox" do |vb|
      if ! File.file?('data_disk.vdi') then
        vb.customize ['createhd', '--filename', 'data_disk', '--size', 409600]
      end
      vb.customize ['storageattach', :id, '--storagectl', 'SCSI Controller', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', 'data_disk.vdi'] 
    end
    config.vm.provision "shell", path: "provision.sh"


### <span>provison.sh</span>


    echo Partition data HD...
    echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk /dev/sdc 2>&1

    echo Create Volume Group:
    sudo vgcreate DataVG /dev/sdc1

    echo Create Logical Volume:
    sudo lvcreate -L 40G DataVG -n DataLV


    echo Create ext4 fs:
    2>&1 sudo mkfs -t ext4 /dev/DataVG/DataLV

    echo Create mount point:
    2>&1 sudo mkdir /data

    echo Config in fstab
    echo "/dev/DataVG/DataLV /data   ext4    defaults        0 0" \
        | sudo tee -a /etc/fstab

    echo Trigger mount:
    2>&1 sudo mount -a



Caveats
-------

  * Tested with *ubuntu/xenial64*. With other base images, some things could change:
      * **'SCSI Controller':** Check actual controller name.
      * **'/dev/sdc and /dev/sdc1':** Check actual device assignment.

