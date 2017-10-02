
echo "Actualitzant caché APT..."
sudo apt-get update

echo "Actualitzant tot el sistema..."
sudo apt-get -y dist-upgrade

echo "Instal·lant build-essential..."
sudo apt-get install -y buid-essential

echo "Instal·lant Node.JS..."
sudo apt-get install -y nodejs-legacy

echo "Instal·lant htop..."
sudo apt-get install -y htop

echo "Hello World..."
sudo adduser --disabled-password --gecos "" joanmi
echo joanmi:fixme | sudo chpasswd
sudo adduser joanmi sudo

echo "Instal·lant Git..."
sudo apt-get -y install git

sudo su - joanmi <<!EOF

echo "Clonant dotfiles..."
git clone https://github.com/bitifet/dotfiles
mv ~/dotfiles/* ~/
mv ~/dotfiles/.??* ~/
rmdir ~/dotfiles

!EOF


inetAddr=$(ifconfig | grep 'inet addr' | head -n 2 | tail -n 1 | sed -r 's/^.*inet addr:([0-9.]*).*$/\1/')
addHostCmd="echo \"${inetAddr}    bacterio\" | sudo tee -a /etc/hosts";

echo "Adding local /etc/hosts entry:"
"${addHostCmd}"

echo ""
echo ""
echo "======================================================================";
echo "SETUP PROCESS FINISHED!!!"
echo ""
echo "Machine LAN address is ${inetAddr}"
echo ""
echo "Type follwing command to add it to your /etc/hosts file"
echo ""
echo "   ${addHostCmd}"
echo ""
echo "Login methods"
echo ""
echo "  1) 'vagrant ssh' (as usual, user ubuntu)"
echo "  2) 'ssh joanmi@bacterio' (personal user)"
echo "     - REMEMBER to change default password which is 'fixme'."
echo "======================================================================";



