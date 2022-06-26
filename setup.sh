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

install_packages() {
  step "Installing APT packages"

  sudo apt install -y \
    ansible \
    apt-transport-https \
    build-essential \
    curl \
    git \
    gnome-session \
    gnome-tweak-tool \
    htop \
    neofetch \
    openjdk-11-jdk \
    openssh-server \
    software-properties-common \
    tmux \
    virtualbox \
    zsh
  check
}

update_system() {
  step "Updating system"
  sudo apt update && sudo apt full-upgrade -y
  check
}

remove_packages() {
  step "Removing APT packages"
  sudo apt purge -y apport
  check
}

cleanup_packages() {
  step "Cleaning APT packages"
  sudo apt autoremove -y
  check
}

install_brave() {
  step "Installing Brave Browser"

  if exists brave-browser; then
    warning "Docker is already installed, skipping install"
  else
    sudo apt install -y apt-transport-https curl
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update
    sudo apt install -y brave-browser
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
    curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
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
  step "Installing Steam"
  sudo dpkg --add-architecture i386
  sudo add-apt-repository multiverse
  sudo apt full-upgrade
  sudo apt install -y steam
  check
}

install_neovim() {
  step "Installing Neovim"
  sudo add-apt-repository -y ppa:neovim-ppa/stable
  sudo apt install -y neovim
  check
}

install_telegram() {
  step "Installing Telegram"
  sudo add-apt-repository -y ppa:atareao/telegram
  sudo apt-get install -y telegram
  check
}

install_spotify() {
  step "Installing Spotify"
  curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add -
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  sudo apt-get update
  sudo apt-get install -y spotify-client
  check
}

install_discord() {
  step "Installing Discord"
  wget "https://discordapp.com/api/download?platform=linux&format=deb" -O discord.deb
  sudo dpkg -i discord.deb
  sudo apt install -f
  sudo rm discord.deb
  check
}

install_vscode() {
  step "Installing VSCode"
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
  sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  rm -f packages.microsoft.gpg
  sudo apt install -y apt-transport-https
  sudo apt update
  sudo apt install -y code
  check
}

install_ghcli() {
  step "Installing GH-CLI"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
  #gh auth login
  check
}

install_gcloud_sdk() {
  step "Installing gcloud sdk"
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  sudo apt install -y apt-transport-https ca-certificates gnupg
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
  sudo apt-get update && sudo apt-get install google-cloud-sdk
  check
}

install_bitwarden() {
  step "Installing bitwarden"
  wget "https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb" -O bitwarden.deb
  sudo dpkg -i bitwarden.deb
  rm bitwarden.deb
  check
}

install_hashicorp() {
  step "Installing hashicorp stuff"
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
  sudo apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
  sudo apt-get update && sudo apt install -y vagrant terraform
  check
}

install_yarn() {
  step "Install yarn and npm-check-updates"
  sudo npm install -g yarn
  sudo npm install -g npm-check-updates
  check
  
}

install_fonts() {
  step "install fantasque sans mono font"
  mkdir -p $HOME/.fonts/
  wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FantasqueSansMono.zip
  unzip FantasqueSansMono.zip
  mv *.ttf $HOME/.fonts/
  rm FantasqueSansMono.zip
  check

}

install_themes() {
  step "Install dracula gedit theme"
  mkdir -p $HOME/.local/share/gedit/styles/
  wget https://raw.githubusercontent.com/dracula/gedit/master/dracula.xml
  mv dracula.xml $HOME/.local/share/gedit/styles/
  check
}

configure_git() {
  step "Configuring Git"
  git config --global user.name "Gustavo Verzola"
  git config --global user.email "verzola@gmail.com"
  git config --global tag.sort -version:refname
  git config --global pull.rebase false
  git config --global push.default current
  git config --global pull.default current
  check
}

create_folders() {
  step "Create user bin folder"
  mkdir -p $HOME/bin $HOME/projects/verzola
  check
}

adjust_clock() {
  step "Configure date to use Local Time"
  sudo timedatectl set-local-rtc 1 --adjust-system-clock
  check
  
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
  rm -f ~/.zshrc
  ln -s ~/projects/verzola/zshrc/.zshrc ~/.zshrc
  check

  step "Changing default shell to zsh"
  chsh -s $(which zsh)
}

configure_tmux() {
  step "Installing Tmux Plugin Manager"
  if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  else
    git -C ~/.tmux/plugins/tpm pull origin master
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
  echo "\n Verzola's Ubuntu 20.04 Setup"

  install_packages
  update_system
  remove_packages
  cleanup_packages
  install_brave
  install_nodejs
  install_neovim
  install_vscode
  install_steam
  install_bitwarden
  install_hashicorp
  install_gcloud_sdk
  install_ghcli
  install_stacer
  install_telegram
  install_spotify
  install_docker
  install_docker_compose
  install_yarn
  install_fonts
  install_themes
  #install_discord
  create_folders
  configure_zsh
  configure_tmux
  configure_vim
  configure_aliases
  configure_git
  adjust_clock

  echo "\nFinished!"
}

setup
