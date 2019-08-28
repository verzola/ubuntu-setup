#!/bin/sh
export DEBIAN_FRONTEND=noninteractive

# Helper functions
get_latest_release() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

echo "Updating system..."
apt update && apt upgrade -y && apt dist-upgrade

echo "Installing APT packages..."
apt install -y \
  apt-transport-https \
  ca-certificates \
  git \
  neovim \
  zsh \
  tmux \
  wget \
  curl \
  unzip \
  htop \
  openssh-server \
  build-essential \
  grub-customizer \
  fonts-firacode \
  steam \
  gnome-tweak-tool \
  darktable \
  krita \
  shotwell \
  gnome-shell-extensions \
  chrome-gnome-shell \
  gnome-session \
  filezilla

echo "Cleaning APT packages..."
apt autoremove
apt autoclean

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

echo "Installing Docker-Compose"
curl -L "https://github.com/docker/compose/releases/download/$(get_latest_release docker/compose)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "Installing NodeJS..."
curl -sL https://deb.nodesource.com/setup_12.x | bash
apt install nodejs

echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "Configuring Git..."
git config --global user.name "Gustavo Verzola"
git config --global user.email "verzola@gmail.com"

echo "Allow HTTP and SSH ports on firewall..."
ufw allow 80
ufw allow 22
