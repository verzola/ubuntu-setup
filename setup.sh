#!/bin/sh

echo "Updating system..."
apt update
apt upgrade
apt dist-upgrade

echo "Installing APT packages..."
apt install -y \
     apt-transport-https \
     ca-certificates \
     git \
     vim \
     zsh \
     tmux \
     wget \
     curl \
     unzip \
     htop \
     gcc \
     g++ \
     make \
     grub-customizer \
     fonts-firacode \
     steam \
     gnome-tweak-tool \
     darktable \
     krita \
     shotwell \
     google-chrome-shell
     
echo "Cleaning APT packages..."
apt autoremove

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

echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh
usermod -aG docker verzola

echo "Installing NodeJS..."
curl -sL https://deb.nodesource.com/setup_12.x | bash
apt install nodejs

echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "Configuring Git..."
git config --global user.name "Gustavo Verzola"
git config --global user.email "verzola@gmail.com"
