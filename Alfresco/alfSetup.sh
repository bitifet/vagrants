#!/usr/bin/env bash
#
# http://docs.alfresco.com/community/tasks/simpleinstall-community-lin-text.html


# Software dependencies:
# ======================

# Refresh package cache:
sudo apt-get update

# Install packages:
sudo apt-get install -y \
    fontconfig \
    libglu1-mesa  \
    libice6 \
    libsm6 \
    libxrender1 \
    libxinerama1 \
    libgluegen2-rt-java \
;


# Network configuration:
# ======================

# Configure port forwarding:
sudo iptables -t nat -I PREROUTING --src 0/0 -p tcp --dport 80 -j REDIRECT --to-ports 8080
sudo iptables -t nat -I PREROUTING --src 0/0 -p tcp --dport 443 -j REDIRECT --to-ports 8443


# Save iptables to file:
sudo iptables-save | sudo tee /etc/firewall.iptables >/dev/null

# Add cront task to reload on reboot:
(sudo EDITOR=/bin/cat crontab -e 2>/dev/null;echo"") | head -n -1 | tee /tmp/rootcrontab > /dev/null
echo "@reboot /sbin/iptables-restore < /etc/firewall.iptables" | tee -a /tmp/rootcrontab > /dev/null
sudo crontab /tmp/rootcrontab
sudo rm /tmp/rootcrontab


# Install preparation:
# ====================

# Create alfresco user:
sudo useradd --shell /bin/bash alfresco
sudo chown alfresco:alfresco /home/alfresco

# Final message:
echo ""
echo "---------------------------------------------------------------------------------------"
echo "Alfresco Community initial setup completed!"
echo "Now you should execute following commands in console to complete alfresco installation:"
echo "  $ sudo su - alfresco"
echo "  $ /vagrant/alfresco-community-installer-201602-linux-x64.bin"
echo "---------------------------------------------------------------------------------------"

