
echo Partition data HD...
echo -e "o\nn\np\n1\n\n\nw" | sudo fdisk /dev/sdc 2>&1

echo Create ext4 fs:
2>&1 sudo mkfs -t ext4 /dev/sdc1

echo Create mount point:
2>&1 sudo mkdir /var/lib/postgresql

echo Config in fstab
echo "/dev/sdc1 /var/lib/postgresql   ext4    defaults        0 0" \
    | sudo tee -a /etc/fstab

echo Trigger mount:
2>&1 sudo mount -a

/vagrant/setup.sh
