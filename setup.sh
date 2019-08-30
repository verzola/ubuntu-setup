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
    grep '"tag_name":' | # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/' # Pluck JSON value
}

exists() {
  command -v "$1" >/dev/null 2>&1
}

step() {
  echo "\n$cyan> $1$reset..."
}

check() {
  echo "$green> ✔️ $reset"
}

warning() {
  echo "⚠️  $1"
}

setup() {
  echo "\n👉 verzola's ubuntu setup 🤘"

  step "Updating system"
    sudo apt update && sudo apt full-upgrade -y
  check

  step "Removing packages"
    sudo apt purge apport
  check

  step "Installing APT packages"
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
  check

  step "Cleaning APT packages"
    sudo apt autoremove -y
  check

  step "Installing snap apps"
    sudo snap install spotify
    sudo snap install discord
    sudo snap install telegram-desktop
    sudo snap install postman
    sudo snap install code --classic
    sudo snap install android-studio --classic
    sudo snap install slack --classic
    sudo snap install google-cloud-sdk --classic
    sudo snap install skype --classic
  check

  step "Installing Google Chrome"
  if exists google-chrome; then
    warning "Google Chrome is already installed, skipping install"
  else
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
    sudo apt update && sudo apt install google-chrome-stable
  fi
  check

  step "Installing Docker"
    if exists docker; then
      warning "Docker is already installed, skipping install"
    else
      curl -fsSL https://get.docker.com -o get-docker.sh
      sh get-docker.sh
      rm get-docker.sh
      usermod -aG docker verzola
      docker --version
    fi
  check

  step " Installing Docker-Compose"
    if exists docker-compose; then
      warning "Docker-compose is already installed, skipping install"
    else
      sudo curl -L "https://github.com/docker/compose/releases/download/$(get_latest_release docker/compose)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      docker-compose --version
    fi
  check

  step "Installing NodeJS"
    if exists node; then
      warning "NodeJS is already installed, skipping install"
    else
      curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
      sudo apt install nodejs
      node --version
    fi
  check

  step "Installing Yarn"
    if exists yarn; then
      warning "Yarn is already installed, skipping install"
    else
      curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
      sudo echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
      sudo apt-get update && sudo apt-get install yarn
      yarn --version
    fi
  check

  step "Installing Stacer"
    if exists stacer; then
      warning "Stacer is already installed, skipping install"
    else
      sudo add-apt-repository ppa:oguzhaninan/stacer -y
      sudo apt install stacer -y
    fi
  check

  step "Allowing HTTP and SSH ports on firewall"
    sudo ufw allow 80
    sudo ufw allow 22
  check

  step "Making Linux use Local Time"
    timedatectl set-local-rtc 1 --adjust-system-clock
  check

  step "Configuring Git"
    git config --global user.name "Gustavo Verzola"
    git config --global user.email "verzola@gmail.com"
  check

  step "Creating projects folder"
    mkdir -p ~/projects/verzola/
  check

  step "Adding zsh config"
    if [ ! -d ~/projects/verzola/zshrc ]; then
      git clone https://github.com/verzola/.zshrc.git ~/projects/verzola/zshrc
    else
      git -C ~/projects/verzola/zshrc pull origin master
    fi
  check

  if [ -d ~/.oh-my-zsh ]; then
    step "Updating Oh My Zsh"
    zsh -ic "upgrade_oh_my_zsh"
  else
    step "Installing Oh My Zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
  fi
  check

  step "Linking zshrc"
    rm ~/.zshrc
    ln -s ~/projects/verzola/zshrc/.zshrc ~/.zshrc
  check

  step "Installing vim-plug"
    if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
      curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
  check

  if [ ! -d ~/projects/verzola/vimrc ]; then
    step "Cloning verzola's .vimrc"
    git clone https://github.com/verzola/.vimrc.git ~/projects/verzola/vimrc
  else
    step "Updating verzola's .vimrc"
    git -C ~/projects/verzola/vimrc pull origin master
  fi
  check

  step "Linking vimrc"
    if [ ! -L ~/.vimrc ]; then
      ln -s ~/projects/verzola/vimrc/.vimrc ~/.vimrc
    fi

    if [ ! -L ~/.config/nvim/init.vim ]; then
      ln -s ~/projects/verzola/vimrc/.vimrc ~/.config/nvim/init.vim
    fi
  check

  step "Installing plugins"
    vim +PlugInstall +qall
  check

  step "Installing Tmux Plugin Manager"
    if [ ! -d ~/.tmux/plugins/tpm ]; then
      git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
      git -C ~/.tmux/plugins/tpm pull origin master
    fi
  check

  step "Fetching tmux config"
    if [ ! -d ~/projects/verzola/tmux.conf ]; then
      git clone https://github.com/verzola/.tmux.conf ~/projects/verzola/tmux.conf
    else
      git -C ~/projects/verzola/tmux.conf pull origin master
    fi
  check

  step "Linking tmux config"
    if [ ! -f ~/.tmux.conf ]; then
      ln -s ~/projects/verzola/tmux.conf/.tmux.conf ~/.tmux.conf
    fi
  check

  step "Installing Tmux plugins"
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
  check

  step "Fetching aliases"
    if [ ! -d ~/projects/verzola/aliases ]; then
      git clone https://github.com/verzola/aliases.git ~/projects/verzola/aliases
    else
      git -C ~/projects/verzola/aliases pull origin master
    fi
  check

  echo "\nFinished! 🎉"
}

setup
