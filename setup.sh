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

  xargs -a packages.txt sudo apt install -y
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

install_nvm() {
  step "Installing NVM"

  if exists nvm; then
    warning "NVM is already installed, skipping install"
  else
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install stable
    nvm use stable
    nvm alias default stable
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

install_neovim() {
  step "Installing Neovim"
  if exists nvim; then
    warning "Neovim is already installed, skipping install"
  else
    wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage -O ~/bin/nvim
  fi
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

install_npm_packages() {
  step "Installing npm packages"
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npm install -g yarn
  npm install -g npm-check-updates
  npm install -g neovim
  check
}

install_pip_packages() {
  step "Installing pip packages"
  pip install pynvim
  check
}

install_fonts() {
  step "Installing FantasqueSansMono nerd font"
  mkdir -p $HOME/.fonts/
  wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FantasqueSansMono.zip
  unzip FantasqueSansMono.zip
  mv *.ttf $HOME/.fonts/
  rm FantasqueSansMono.zip
  check
}

install_themes() {
  step "Installing dracula gedit theme"
  mkdir -p $HOME/.local/share/gedit/styles/
  wget https://raw.githubusercontent.com/dracula/gedit/master/dracula.xml
  mv dracula.xml $HOME/.local/share/gedit/styles/
  check
}

install_starship() {
  step "Installing starship"
  curl -sS https://starship.rs/install.sh | sh
  check
}

install_fzf() {
  step "Installing fzf"
  if exists fzf; then
    warning "FZF is already installed, skipping install"
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf;
    ~/.fzf/install
  fi
  check
}

create_folders() {
  step "Create user bin folder"
  mkdir -p $HOME/bin $HOME/projects
  check
}

configure_dotfiles() {
  step "Fetching dotfiles"
  if [ ! -d ~/dotfiles ]; then
    git clone https://github.com/verzola/dotfiles.git ~/dotfiles
  else
    git -C ~/dotfiles pull origin main
  fi
  sh -c "cd ~/dotfiles && make"
  check
}

configure_tmux() {
  step "Installing Tmux Plugin Manager"
  if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  else
    git -C ~/.tmux/plugins/tpm pull origin master
  fi
  check

  step "Installing tmux plugins"
  ~/.tmux/plugins/tpm/scripts/install_plugins.sh
  check
}

configure_zsh() {
  step "Changing default shell to zsh"
  chsh -s $(which zsh)
}

adjust_clock() {
  step "Configure date to use Local Time"
  sudo timedatectl set-local-rtc 1 --adjust-system-clock
  check
}

setup() {
  echo "\n Verzola's Ubuntu 22.04 Setup"

  install_packages
  update_system
  remove_packages
  cleanup_packages
  create_folders
  install_brave
  install_nvm
  install_neovim
  install_bitwarden
  install_hashicorp
  install_gcloud_sdk
  install_ghcli
  install_stacer
  install_telegram
  install_spotify
  install_docker
  install_docker_compose
  install_npm_packages
  install_pip_packages
  install_fonts
  install_themes
  install_starship
  install_fzf
  adjust_clock
  configure_dotfiles
  configure_tmux
  configure_zsh

  echo "\nFinished!"
}

setup
