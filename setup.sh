#!/bin/sh

set -e

export DEBIAN_FRONTEND=noninteractive

# Helper functions
get_latest_release() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

exists() {
  command -v "$1" >/dev/null 2>&1
}

setup() {
    echo "Updating system..."
    apt update && apt full-upgrade -y

    echo "Removing apport..."
    apt purge apport

    echo "Installing APT packages..."
    apt install -y \
      git \
      neovim \
      zsh \
      tmux \
      curl \
      htop \
      openssh-server \
      build-essential \
      grub-customizer \
      shotwell \
      krita \
      darktable \
      fonts-firacode \
      gnome-tweak-tool \
      gnome-shell-extensions \
      chrome-gnome-shell \
      gnome-session \
      steam

    echo "Cleaning APT packages..."
    apt autoremove -y
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

    if exists google-chrome; then
      echo "Google Chrome is already installed, skipping install..."
    else
      echo "Installing Google Chrome..."
      wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
      sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
      apt update && apt install google-chrome-stable
    fi

    if exists docker; then
      echo "Docker is already installed, skipping install..."
    else
      echo "Installing Docker..."
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh
      rm get-docker.sh
      usermod -aG docker verzola
      docker --version
    fi

    if exists docker-compose; then
      echo "Docker-compose is already installed, skipping install..."
    else
      echo "Installing Docker-Compose"
      curl -L "https://github.com/docker/compose/releases/download/$(get_latest_release docker/compose)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      chmod +x /usr/local/bin/docker-compose
      docker-compose --version
    fi

    if exists node; then
      echo "NodeJS is already installed, skipping install..."
    else
      echo "Installing NodeJS..."
      curl -sL https://deb.nodesource.com/setup_12.x | bash
      apt install nodejs
      node --version
    fi

    if exists yarn; then
      echo "Yarn is already installed, skipping install..."
    else
      echo "Installing Yarn..."
      curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
      echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
      apt-get update && apt-get install yarn
      yarn --version
    fi

    if exists stacer; then
      echo "Stacer is already installed, skipping install..."
    else
      echo "Installing Stacer..."
      add-apt-repository ppa:oguzhaninan/stacer -y
      apt install stacer -y
    fi

    if [ -d ~/.oh-my-zsh ]; then
      echo "Updating Oh My Zsh..."
      zsh -ic "upgrade_oh_my_zsh"
    else
      echo "Installing Oh My Zsh..."
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    fi

    echo "Configuring Git..."
    git config --global user.name "Gustavo Verzola"
    git config --global user.email "verzola@gmail.com"

    echo "Allowing HTTP and SSH ports on firewall..."
    ufw allow 80
    ufw allow 22

    echo "Making Linux use Local Time..."
    timedatectl set-local-rtc 1 --adjust-system-clock

    echo "Creating projects folder..."
    mkdir -p ~/projects/verzola/

    echo "Adding tmux configuration..."
    curl https://raw.githubusercontent.com/verzola/.tmux.conf/master/install.sh | bash

    echo "Adding aliases..."
    curl https://raw.githubusercontent.com/verzola/aliases/master/install.sh | bash
}

setup
