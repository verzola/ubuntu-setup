#!/bin/sh
set -e

reset="\033[0m"
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
cyan="\033[36m"
white="\033[37m"

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
    echo "$cyan> Updating system... $reset"
    sudo apt update && sudo apt full-upgrade -y
    echo "$green ✓ $reset"

    echo "$cyan> Removing apport...$reset"
    sudo apt purge apport
    echo "$green ✓ $reset"

    echo "$cyan> Installing APT packages...$reset"
    sudo apt install -y \
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
    echo "$green ✓ $reset"

    echo "$cyan> Cleaning APT packages...$reset"
    sudo apt autoremove -y
    echo "$green ✓ $reset"

    echo "$cyan> Installing snap apps...$reset"
    sudo snap install spotify
    sudo snap install discord
    sudo snap install telegram-desktop
    sudo snap install postman
    sudo snap install code --classic
    sudo snap install android-studio --classic
    sudo snap install slack --classic
    sudo snap install google-cloud-sdk --classic
    sudo snap install skype --classic
    echo "$green ✓ $reset"

    if exists google-chrome; then
      echo "$cyan> Google Chrome is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing Google Chrome...$reset"
      wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
      sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
      sudo apt update && sudo apt install google-chrome-stable
    fi
    echo "$green ✓ $reset"

    if exists docker; then
      echo "$cyan> Docker is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing Docker...$reset"
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh
      rm get-docker.sh
      usermod -aG docker verzola
      docker --version
    fi
    echo "$green ✓ $reset"

    if exists docker-compose; then
      echo "$cyan> Docker-compose is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing Docker-Compose...$reset"
      sudo curl -L "https://github.com/docker/compose/releases/download/$(get_latest_release docker/compose)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      docker-compose --version
    fi
    echo "$green ✓ $reset"

    if exists node; then
      echo "$cyan> NodeJS is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing NodeJS...$reset"
      curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
      sudo apt install nodejs
      node --version
    fi
    echo "$green ✓ $reset"

    if exists yarn; then
      echo "$cyan> Yarn is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing Yarn...$reset"
      curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
      sudo echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
      sudo apt-get update && sudo apt-get install yarn
      yarn --version
    fi
    echo "$green ✓ $reset"

    if exists stacer; then
      echo "$cyan> Stacer is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing Stacer...$reset"
      sudo add-apt-repository ppa:oguzhaninan/stacer -y
      sudo apt install stacer -y
    fi
    echo "$green ✓ $reset"

    echo "$cyan> Allowing HTTP and SSH ports on firewall...$reset"
    sudo ufw allow 80
    sudo ufw allow 22
    echo "$green ✓ $reset"

    echo "$cyan> Making Linux use Local Time...$reset"
    timedatectl set-local-rtc 1 --adjust-system-clock
    echo "$green ✓ $reset"

    echo "$cyan> Configuring Git...$reset"
    git config --global user.name "Gustavo Verzola"
    git config --global user.email "verzola@gmail.com"
    echo "$green ✓ $reset"

    echo "$cyan> Creating projects folder..."
    mkdir -p ~/projects/verzola/
    echo "$green ✓ $reset"

    echo "$cyan> Adding zsh config...$reset"
    sh -c "$(wget -O - https://zsh.verzola.net)"

    echo "$cyan> Adding vim config...$reset"
    sh -c "$(wget -O - https://vim.verzola.net)"

    echo "$cyan> Adding tmux config...$reset"
    sh -c "$(wget -O - https://tmux.verzola.net)"

    echo "$cyan> Adding aliases...$reset"
    sh -c "$(wget -O - https://aliases.verzola.net)"

    echo "$cyan Finished! $green ✓ $reset"
}

setup
