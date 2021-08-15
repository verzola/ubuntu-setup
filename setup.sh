#!/bin/sh
set -e

# color vars
reset="\033[0m"
success="\033[32m"
warning="\033[33m"
main="\033[34m"

# env vars
export DEBIAN_FRONTEND=noninteractive
export RUNZSH=no

# Helper functions
get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

exists() {
  command -v "$1" >/dev/null 2>&1
}

step() {
  echo "\n$main> $1$reset..."
}

check() {
  echo "$success> ✅$reset"
}

warning() {
  echo "$warning>⚠️  $1"
}

install_chrome() {
  step "Installing Google Chrome"

  if exists google-chrome; then
    warning "Google Chrome is already installed, skipping install"
  else
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
    sudo apt update && sudo apt install -y google-chrome-stable
  fi

  check
}

install_docker() {
  step "Installing Docker"

  if exists docker; then
    warning "Docker is already installed, skipping install"
  else
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    sudo usermod -aG docker $USER
    docker --version
  fi

  check
}

install_docker_compose() {
  step "Installing Docker Compose"

  if exists docker-compose; then
    warning "Docker-compose is already installed, skipping install"
  else
    sudo curl -L "https://github.com/docker/compose/releases/download/$(get_latest_release docker/compose)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version
  fi

  check
}

install_nodejs() {
  step "Installing NodeJS"

  if exists node; then
    warning "NodeJS is already installed, skipping install"
  else
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt install -y nodejs
    node --version
  fi

  check
}

install_stacer() {
  step "Installing Stacer"

  if exists stacer; then
    warning "Stacer is already installed, skipping install"
  else
    sudo apt install -y stacer
  fi

  check
}

install_steam() {
  sudo dpkg --add-architecture i386
  sudo add-apt-repository multiverse
  sudo apt full-upgrade
  sudo apt install -y steam
}

install_neovim() {
  sudo add-apt-repository ppa:neovim-ppa/stable
  sudo apt install -y neovim
}

install_telegram() {
  sudo add-apt-repository ppa:atareao/telegram
  sudo apt-get install -y telegram
}

install_spotify() {
  curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | sudo apt-key add - 
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  sudo apt-get update && sudo apt-get install -y spotify-client
}

install_discord() {
  wget "https://discordapp.com/api/download?platform=linux&format=deb" -O discord.deb
  sudo dpkg -i discord.deb
  sudo apt install -f
  sudo rm discord.deb
}

configure_zsh() {
  step "Adding zsh config"
  if [ ! -d ~/projects/verzola/zshrc ]; then
    git clone https://github.com/verzola/.zshrc.git ~/projects/verzola/zshrc
  else
    git -C ~/projects/verzola/zshrc pull origin main
  fi
  check

  step "Linking zshrc"
  rm ~/.zshrc
  ln -s ~/projects/verzola/zshrc/.zshrc ~/.zshrc
  check
}

configure_tmux() {
  step "Installing Tmux Plugin Manager"
  if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  else
    git -C ~/.tmux/plugins/tpm pull origin main
  fi
  check

  step "Fetching tmux config"
  if [ ! -d ~/projects/verzola/tmux.conf ]; then
    git clone https://github.com/verzola/.tmux.conf.git ~/projects/verzola/tmux.conf
  else
    git -C ~/projects/verzola/tmux.conf pull origin main
  fi
  check

  step "Linking tmux config"
  if [ ! -f ~/.tmux.conf ]; then
    ln -s ~/projects/verzola/tmux.conf/.tmux.conf ~/.tmux.conf
  fi
  check

  step "Installing tmux plugins"
  ~/.tmux/plugins/tpm/scripts/install_plugins.sh
  check
}

configure_vim() {
  step "Installing vim-plug"
  if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
  check

  if [ ! -d ~/projects/verzola/vimrc ]; then
    step "Fetching vim config"
    git clone https://github.com/verzola/.vimrc.git ~/projects/verzola/vimrc
  else
    step "Updating vim config"
    git -C ~/projects/verzola/vimrc pull origin main
  fi
  check

  step "Linking vim config"
  if [ ! -L ~/.vimrc ]; then
    ln -s ~/projects/verzola/vimrc/.vimrc ~/.vimrc
  fi

  if [ ! -L ~/.config/nvim/init.vim ]; then
    mkdir -p ~/.config/nvim
    ln -s ~/projects/verzola/vimrc/.vimrc ~/.config/nvim/init.vim
  fi
  check

  step "Installing vim plugins"
  vim +PlugInstall +qall
  check
}

configure_aliases() {
  step "Fetching aliases"
  if [ ! -d ~/projects/verzola/aliases ]; then
    git clone https://github.com/verzola/aliases.git ~/projects/verzola/aliases
  else
    git -C ~/projects/verzola/aliases pull origin main
  fi
  check
}

setup() {
  echo "\n Verzola's Ubuntu 21.04 Setup"

  step "Updating system"
  sudo apt update && sudo apt full-upgrade -y
  check

  step "Removing APT packages"
  sudo apt purge -y apport
  check

  step "Installing APT packages"
  sudo apt install -y \
    software-properties-common \
    git \
    zsh \
    tmux \
    curl \
    htop \
    openssh-server \
    build-essential
  check

  step "Cleaning APT packages"
  sudo apt autoremove -y
  check

  install_chrome
  install_docker
  install_docker_compose
  install_nodejs
  install_stacer
  install_steam
  install_neovim
  install_telegram
  install_spotify
  install_discord

  step "Configure date to use Local Time"
  sudo timedatectl set-local-rtc 1 --adjust-system-clock
  check

  step "Configuring Git"
  git config --global user.name "Gustavo Verzola"
  git config --global user.email "verzola@gmail.com"
  git config --global tag.sort -version:refname
  check

  step "Creating projects folder"
  mkdir -p ~/projects/verzola/
  check

  configure_zsh
  configure_tmux
  configure_vim
  configure_aliases

  echo "\nFinished!"
}

setup
