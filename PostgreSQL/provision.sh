
echo Partition data HD...
echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk /dev/sdc 2>&1

echo Create Volume Group:
sudo vgcreate DataVG /dev/sdc1

echo Create Logical Volume:
sudo lvcreate -L 20G DataVG -n DataLV

echo Create ext4 fs:
2>&1 sudo mkfs -t ext4 /dev/DataVG/DataLV

echo Create mount point:
2>&1 sudo mkdir -p /var/lib/postgresql

echo Config in fstab
echo "/dev/DataVG/DataLV    /var/lib/postgresql   ext4    defaults        0 0" \
    | sudo tee -a /etc/fstab

echo Trigger mount:
2>&1 sudo mount -a


/vagrant/setup.sh
