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
  echo "$warning> ⚠️  $1"
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

cleanup_packages() {
  step "Cleaning APT packages"
  sudo apt autoremove -y
  check
}

create_folders() {
  step "Create user bin folder"
  mkdir -p $HOME/bin $HOME/projects
  check
}

install_brave() {
  if exists brave-browser; then
    warning "Brave Browser already installed, skipping"
    return
  fi

  step "Installing Brave Browser"
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
  sudo sh -c "apt update; apt install brave-browser -y"
  check
}

install_nvm() {
  if exists nvm; then
    warning "NVM already installed, skipping"
    return
  fi

  step "Installing NVM"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install stable
  nvm use stable
  nvm alias default stable
  check
}

install_neovim() {
  step "Installing Neovim"
  if exists nvim; then
    warning "Neovim already installed, skipping"
    return
  fi
  wget https://github.com/neovim/neovim/releases/download/stable/nvim.appimage -O ~/bin/nvim
  check
}

install_docker() {
  if exists docker; then
    warning "Docker already installed, skipping"
    return
  fi

  step "Installing Docker"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm get-docker.sh
  sudo usermod -aG docker $USER
  docker --version
  check
}

install_docker_compose() {
  if exists docker-compose; then
    warning "Docker Compose already installed, skipping"
    return
  fi

  step "Installing Docker Compose"
  sudo curl -L "https://github.com/docker/compose/releases/download/$(get_latest_release docker/compose)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  docker-compose --version
  check
}

install_stacer() {
  if exists stacer; then
    warning "Stacer already installed, skipping"
    return
  fi

  step "Installing Stacer"
  sudo apt install -y stacer
  check
}

install_spotify() {
  if exists spotify-client; then
    warning "Spotify already installed, skipping"
    return
  fi

  step "Installing Spotify"
  curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  sudo sh -c "apt-get update ; apt-get install -y spotify-client"
  check
}

install_ghcli() {
  if exists gh; then
    warning "GH-CLI already installed, skipping"
    return
  fi

  step "Installing GH-CLI"
  (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
  check
}

install_bitwarden() {
  if exists bitwarden; then
    warning "Bitwarden already installed, skipping"
    return
  fi

  step "Installing Bitwarden"
  wget "https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb" -O bitwarden.deb
  sudo dpkg -i bitwarden.deb
  rm bitwarden.deb
  check
}

install_hashicorp() {
  if exists terraform; then
    warning "Terraform already installed, skipping"
    return
  fi

  step "Installing hashicorp stuff"
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update && sudo apt install -y terraform
  check
}

install_npm_packages() {
  step "Installing npm packages"
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npm install -g yarn
  npm install -g npm-check-updates
  npm install -g neovim
  npm install -g prettier
  check
}

install_pip_packages() {
  step "Installing pip packages"
  pip install pynvim
  check
}

install_fonts() {
  mkdir -p $HOME/.fonts/
  bash nerdfont_install.sh
  check
}

install_themes() {
  step "Installing dracula gedit theme"
  if [ -f "$HOME/.local/share/gedit/styles/dracula.xml" ]; then
    warning "Dracula theme already installed, skipping"
    return
  fi

  mkdir -p $HOME/.local/share/gedit/styles/
  wget https://raw.githubusercontent.com/dracula/gedit/master/dracula.xml
  mv dracula.xml $HOME/.local/share/gedit/styles/
  check
}

install_starship() {
  if exists starship; then
    warning "Starship already installed, skipping"
    return
  fi

  step "Installing starship"
  curl -sS https://starship.rs/install.sh | sh
  check
}

install_fzf() {
  if [ -d "$HOME/.fzf" ]; then
    warning "fzf already installed, skipping"
    return
  fi

  step "Installing fzf"
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install
  check
}

adjust_clock() {
  step "Configure date to use Local Time"
  sudo timedatectl set-local-rtc 1 --adjust-system-clock
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
  check
}

tweak_inotify() {
  step "Tweaking inotify"
  echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
  cat /proc/sys/fs/inotify/max_user_watches
  check
}

add_to_sudoers() {
  step "Adding user to sudoers group"
  if groups $USER | grep -q "\bsudo\b"; then
    warning "User already in sudo group, skipping"
  else
    sudo usermod -aG sudo $USER
    check
  fi
}

setup() {
  echo "\n Verzola's Ubuntu Setup"

  if [ -z "$1" ]; then
    # No argument passed, run all steps
    install_packages
    update_system
    cleanup_packages
    create_folders
    install_brave
    install_nvm
    install_npm_packages
    install_themes
    install_starship
    install_fzf
    install_neovim
    install_docker
    install_docker_compose
    install_bitwarden
    install_hashicorp
    install_ghcli
    install_stacer
    install_spotify
    adjust_clock
    configure_dotfiles
    configure_zsh
    tweak_inotify
    add_to_sudoers
    install_fonts
    echo "\nFinished!"
  else
    # Argument passed, run specific step
    "$1"
  fi
}

setup "$1"
