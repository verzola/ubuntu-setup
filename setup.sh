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
    echo "$green> ✓ $reset"

    echo "$cyan> Removing apport...$reset"
    sudo apt purge apport
    echo "$green> ✓ $reset"

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
    echo "$green> ✓ $reset"

    echo "$cyan> Cleaning APT packages...$reset"
    sudo apt autoremove -y
    echo "$green> ✓ $reset"

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
    echo "$green> ✓ $reset"

    if exists google-chrome; then
      echo "$cyan> Google Chrome is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing Google Chrome...$reset"
      wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
      sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
      sudo apt update && sudo apt install google-chrome-stable
    fi
    echo "$green> ✓ $reset"

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
    echo "$green> ✓ $reset"

    if exists docker-compose; then
      echo "$cyan> Docker-compose is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing Docker-Compose...$reset"
      sudo curl -L "https://github.com/docker/compose/releases/download/$(get_latest_release docker/compose)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
      docker-compose --version
    fi
    echo "$green> ✓ $reset"

    if exists node; then
      echo "$cyan> NodeJS is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing NodeJS...$reset"
      curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
      sudo apt install nodejs
      node --version
    fi
    echo "$green> ✓ $reset"

    if exists yarn; then
      echo "$cyan> Yarn is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing Yarn...$reset"
      curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
      sudo echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
      sudo apt-get update && sudo apt-get install yarn
      yarn --version
    fi
    echo "$green> ✓ $reset"

    if exists stacer; then
      echo "$cyan> Stacer is already installed, skipping install...$reset"
    else
      echo "$cyan> Installing Stacer...$reset"
      sudo add-apt-repository ppa:oguzhaninan/stacer -y
      sudo apt install stacer -y
    fi
    echo "$green> ✓ $reset"

    echo "$cyan> Allowing HTTP and SSH ports on firewall...$reset"
    sudo ufw allow 80
    sudo ufw allow 22
    echo "$green> ✓ $reset"

    echo "$cyan> Making Linux use Local Time...$reset"
    timedatectl set-local-rtc 1 --adjust-system-clock
    echo "$green> ✓ $reset"

    echo "$cyan> Configuring Git...$reset"
    git config --global user.name "Gustavo Verzola"
    git config --global user.email "verzola@gmail.com"
    echo "$green ✓ $reset"

    echo "$cyan> Creating projects folder..."
    mkdir -p ~/projects/verzola/
    echo "$green> ✓ $reset"

    echo "$cyan> Adding zsh config...$reset"
    if [ ! -d ~/projects/verzola/zshrc ]; then
      git clone https://github.com/verzola/.zshrc.git ~/projects/verzola/zshrc
    else
      git -C ~/projects/verzola/zshrc pull origin master
    fi
    echo "$green> ✓ $reset"

    echo "$cyan> Linking zshrc...$reset"
    if [ ! -f ~/.zshrc ]; then
        ln -s ~/projects/verzola/zshrc/.zshrc ~/.zshrc
    fi
    echo "$green> ✓ $reset"

    if [ -d ~/.oh-my-zsh ]; then
      echo "$cyan> Updating Oh My Zsh...$reset"
      zsh -ic "upgrade_oh_my_zsh"
    else
      echo "$cyan> Installing Oh My Zsh...$reset"
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    fi
    echo "$green> ✓ $reset"

    echo "$cyan> Installing vim-plug...$reset"
    if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
    echo "$green> ✓ $reset"

    if [ ! -d ~/projects/verzola/vimrc ]; then
        echo "$cyan> Cloning verzola's .vimrc...$reset"
        git clone https://github.com/verzola/.vimrc.git ~/projects/verzola/vimrc
    else
        echo "$cyan> Updating verzola's .vimrc...$reset"
        git -C ~/projects/verzola/vimrc pull origin master
    fi
    echo "$green> ✓ $reset"

    echo "$cyan> Linking vimrc...$reset"
    if [ ! -L ~/.vimrc ]; then
        ln -s ~/projects/vimrc/.vimrc ~/.vimrc
        ln -s ~/projects/vimrc/.vimrc ~/.config/nvim/init.vim
    fi
    echo "$green> ✓ $reset"

    echo "$cyan> Installing plugins...$reset"
    vim +PlugInstall +qall
    echo "$green> ✓ $reset"

    echo "$cyan> Installing Tmux Plugin Manager...$reset"
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        git -C ~/.tmux/plugins/tpm pull origin master
    fi
    echo "$green> ✓ $reset"

    echo "$cyan> Fetching tmux config...$reset"
    if [ ! -d ~/projects/verzola/tmux.conf ]; then
        git clone https://github.com/verzola/.tmux.conf ~/projects/verzola/tmux.conf
    else
        git -C ~/projects/verzola/tmux.conf pull origin master
    fi
    echo "$green> ✓ $reset"

    echo "$cyan> Linking tmux config...$reset"
    if [ ! -f ~/.tmux.conf ]; then
        ln -s ~/projects/verzola/tmux.conf/.tmux.conf ~/.tmux.conf
    fi
    echo "$green> ✓ $reset"

    echo "$cyan> Fetching aliases...$reset"
    if [ ! -d ~/projects/verzola/aliases ]; then
        git clone https://github.com/verzola/aliases.git ~/projects/verzola/aliases
    else
        git -C ~/projects/aliases pull origin master
    fi
    echo "$green> ✓ $reset"

    echo "$cyan> Finished! $green ✓ $reset"
}

setup
