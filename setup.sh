#!/bin/sh

echo "Updating system..."
apt update
apt upgrade

echo "Installing APT packages..."
apt install \
     git \
     vim \
     curl \
     unzip \
     gcc \
     g++ \
     make \
     zsh \
     grub-customizer \
     fonts-firacode \
     steam \
     gnome-tweak-tool \
     darktable \
     krita \
     shotwell

echo "Installing snap apps..."
snap install spotify
snap install discord
snap install telegram-desktop
snap install postman
snap install code --classic
snap install android-studio --classic
snap install slack --classic
snap install google-cloud-sdk --classic
snap install skype --classic

echo "installing Google Chrome..."
sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
apt update
apt install google-chrome

echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh
usermod -aG docker $USER

echo "Installing NodeJS..."
curl -sL https://deb.nodesource.com/setup_12.x | bash
apt install nodejs

echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "Configuring Git..."
git config --global user.name "Gustavo Verzola"
git config --global user.email "verzola@gmail.com"
