#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_FILE="$SCRIPT_DIR/packages.txt"

if [[ $EUID -eq 0 ]]; then
  printf 'This script must be run as a regular user with sudo access.\n' >&2
  exit 1
fi

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ubuntu-setup"
LOG_FILE="$LOG_DIR/setup.log"

init_logging() {
  if mkdir -p "$LOG_DIR" 2>/dev/null; then
    exec > >(tee -a "$LOG_FILE") 2>&1
    printf '\n[%s] Starting Ubuntu setup\n' "$(date '+%Y-%m-%d %H:%M:%S')"
  fi
}

# color vars
reset="\033[0m"
success="\033[32m"
warning="\033[33m"
main="\033[34m"
error="\033[31m"

# env vars
export DEBIAN_FRONTEND=noninteractive
export RUNZSH=no
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

TEMP_PATHS=()

cleanup_temp_paths() {
  local path
  for path in "${TEMP_PATHS[@]}"; do
    rm -rf -- "$path"
  done
}

trap cleanup_temp_paths EXIT

# Helper functions
exists() {
  command -v "$1" >/dev/null 2>&1
}

package_installed() {
  local package="$1"
  if [[ "$package" == "libfuse2" ]]; then
    dpkg-query -W -f='${Status}' "libfuse2" 2>/dev/null | grep -q '^install ok installed$' ||
      dpkg-query -W -f='${Status}' "libfuse2t64" 2>/dev/null | grep -q '^install ok installed$'
    return
  fi
  dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q '^install ok installed$'
}

step() {
  printf '\n%b> %s%b...\n' "$main" "$1" "$reset"
}

check() {
  printf '%b> Done%b\n' "$success" "$reset"
}

warning() {
  printf '%b> Warning: %s%b\n' "$warning" "$1" "$reset"
}

fail() {
  printf '%bError: %s%b\n' "$error" "$1" "$reset" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  printf 'Error on line %s: command failed: %s (exit %s)\n' "$1" "$2" "$exit_code" >&2
  exit "$exit_code"
}

trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

require_command() {
  if ! exists "$1"; then
    fail "Required command not found: $1"
  fi
}

require_file() {
  local file_path="$1"
  [[ -f "$file_path" ]] || fail "Required file not found: $file_path"
}

download_file() {
  local url="$1"
  local destination="$2"

  mkdir -p "$(dirname "$destination")"
  if exists curl; then
    curl --fail --location --silent --show-error "$url" --output "$destination"
  elif exists wget; then
    wget --quiet --output-document="$destination" "$url"
  else
    require_command curl
  fi
}

apt_get_update() {
  sudo apt-get update
}

install_apt_packages() {
  local -a packages=("$@")

  if ((${#packages[@]} == 0)); then
    return 0
  fi

  apt_get_update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -- "${packages[@]}"
}

validate_environment() {
  local architecture

  [[ -r /etc/os-release ]] || fail 'Cannot identify the operating system.'
  # shellcheck disable=SC1091
  source /etc/os-release
  case "${ID:-}" in
    ubuntu | debian) ;;
    *) fail "Unsupported operating system: ${PRETTY_NAME:-unknown}." ;;
  esac

  architecture="$(uname -m)"
  case "$architecture" in
    x86_64 | aarch64 | armv7l) ;;
    *) fail "Unsupported architecture: $architecture." ;;
  esac

  exists sudo || fail 'sudo is required.'
  sudo -v || fail 'The current user does not have sudo access.'
  if exists curl; then
    curl --fail --silent --show-error --max-time 10 https://packages.microsoft.com/keys/microsoft.asc >/dev/null ||
      fail 'Internet connection is unavailable.'
  elif exists wget; then
    wget --quiet --timeout=10 --spider https://packages.microsoft.com/keys/microsoft.asc ||
      fail 'Internet connection is unavailable.'
  else
    fail 'curl or wget is required for downloads.'
  fi
}

install_packages() {
  local package
  local -a missing_packages=()

  require_file "$PACKAGES_FILE"
  step "Installing APT packages"
  while IFS= read -r package; do
    if ! package_installed "$package"; then
      if [[ "$package" == "libfuse2" ]] && apt-cache show libfuse2t64 >/dev/null 2>&1; then
        missing_packages+=("libfuse2t64")
      else
        missing_packages+=("$package")
      fi
    fi
  done < <(grep -Ev '^[[:space:]]*(#|$)' "$PACKAGES_FILE")

  if ((${#missing_packages[@]} == 0)); then
    warning "All APT packages are already installed, skipping"
    return
  fi

  install_apt_packages "${missing_packages[@]}"
  check
}

configure_git() {
  step "Configuring Git"

  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global rerere.enabled true
  git config --global core.editor "${EDITOR:-nvim}"

  if [[ -z "$(git config --global --get user.name || true)" ]]; then
    warning "Git user.name is not configured"
  fi
  if [[ -z "$(git config --global --get user.email || true)" ]]; then
    warning "Git user.email is not configured"
  fi
  check
}

configure_ssh() {
  local ssh_dir="$HOME/.ssh"
  local key_file="$ssh_dir/id_ed25519"
  local answer

  step "Configuring SSH for GitHub"
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  if [[ ! -f "$key_file" ]]; then
    if [[ -t 0 ]]; then
      read -r -p "Generate an Ed25519 SSH key for GitHub? [y/N] " answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        ssh-keygen -t ed25519 -f "$key_file" -C "$USER@$(hostname)"
      else
        warning "SSH key generation skipped"
      fi
    else
      warning "SSH key generation skipped because no interactive terminal is available"
    fi
  else
    warning "SSH key already exists, skipping generation"
  fi

  if [[ -f "$key_file" ]]; then
    chmod 600 "$key_file"
    if [[ -f "$key_file.pub" ]]; then
      chmod 644 "$key_file.pub"
    fi
    if ! ssh-add -l >/dev/null 2>&1; then
      eval "$(ssh-agent -s)" >/dev/null
    fi
    ssh-add "$key_file" >/dev/null 2>&1 || true
  fi

  touch "$ssh_dir/known_hosts"
  chmod 644 "$ssh_dir/known_hosts"
  if ! ssh-keygen -F github.com -f "$ssh_dir/known_hosts" >/dev/null 2>&1; then
    ssh-keyscan -H github.com >>"$ssh_dir/known_hosts" 2>/dev/null
  fi
  check
}

update_system() {
  step "Updating system"
  apt_get_update
  sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
  check
}

cleanup_packages() {
  step "Cleaning APT packages"
  sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
  check
}

create_folders() {
  step "Create user bin folder"
  mkdir -p "$HOME/bin" "$HOME/.local/bin" "$HOME/projects"

  if exists batcat && ! exists bat; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  fi

  if exists fdfind && ! exists fd; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
  check
}

install_brave() {
  if exists brave-browser || package_installed brave-browser; then
    warning "Brave Browser already installed, skipping"
    return
  fi

  step "Installing Brave Browser"
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSLo /etc/apt/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  sudo rm -f /etc/apt/sources.list.d/brave-browser-release.list
  sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
  apt_get_update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y brave-browser
  check
}

install_vscode() {
  if exists code || package_installed code; then
    warning "Visual Studio Code already installed, skipping"
    return
  fi

  step "Installing Visual Studio Code"
  local temp_dir
  temp_dir="$(mktemp -d)"
  TEMP_PATHS+=("$temp_dir")

  if ! exists gpg; then
    apt_get_update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg
  fi

  download_file "https://packages.microsoft.com/keys/microsoft.asc" "$temp_dir/microsoft.asc"
  gpg --dearmor --output "$temp_dir/microsoft.gpg" "$temp_dir/microsoft.asc"
  sudo install -D -m 0644 "$temp_dir/microsoft.gpg" /etc/apt/keyrings/packages.microsoft.gpg
  sudo rm -f /etc/apt/sources.list.d/vscode.list
  printf '%b\n' "Types: deb\nURIs: https://packages.microsoft.com/repos/code\nSuites: stable\nComponents: main\nArchitectures: $(dpkg --print-architecture)\nSigned-By: /etc/apt/keyrings/packages.microsoft.gpg" |
    sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null
  apt_get_update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y code
  check
}

install_antigravity() {
  if exists antigravity || package_installed antigravity; then
    warning "Antigravity already installed, skipping"
    return
  fi

  step "Installing Antigravity"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl --fail --silent --show-error --location https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg |
    sudo gpg --dearmor --yes --output /etc/apt/keyrings/antigravity-repo-key.gpg
  printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main' |
    sudo tee /etc/apt/sources.list.d/antigravity.list >/dev/null
  apt_get_update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y antigravity
  check
}

install_antigravity_cli() {
  if exists agy || [[ -x "$HOME/.local/bin/agy" ]]; then
    warning "Antigravity CLI already installed, skipping"
    return
  fi

  step "Installing Antigravity CLI"
  curl --fail --silent --show-error --location https://antigravity.google/cli/install.sh | bash
  check
}

install_nvm() {
  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1090,SC1091
    source "$NVM_DIR/nvm.sh"
    if exists node; then
      warning "NVM and Node.js already installed, skipping"
      return
    fi
    warning "NVM already installed; installing Node.js"
  else
    step "Installing NVM"
    curl --fail --silent --show-error --location https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.7/install.sh | bash
    # shellcheck disable=SC1090,SC1091
    source "$NVM_DIR/nvm.sh"
  fi

  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'
  check
}

install_starship() {
  if exists starship; then
    warning "Starship already installed, skipping"
    return
  fi

  step "Installing starship"
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
  check
}

install_neovim() {
  if exists nvim || [[ -x "$HOME/bin/nvim" ]]; then
    warning "Neovim already installed, skipping"
    return
  fi

  step "Installing Neovim"
  local asset temp_dir
  case "$(uname -m)" in
    x86_64) asset=nvim-linux-x86_64.appimage ;;
    aarch64) asset=nvim-linux-arm64.appimage ;;
    *) fail "Neovim's official AppImage is unavailable for this architecture: $(uname -m)." ;;
  esac
  temp_dir="$(mktemp -d)"
  TEMP_PATHS+=("$temp_dir")
  download_file "https://github.com/neovim/neovim/releases/latest/download/$asset" "$temp_dir/$asset"
  install -m 0755 "$temp_dir/$asset" "$HOME/bin/nvim"
  check
}

install_docker() {
  if exists docker || package_installed docker-ce; then
    warning "Docker already installed, skipping"
  else
    step "Installing Docker"
    apt_get_update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    local codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
    if [[ -z "$codename" ]] && [[ -r /etc/os-release ]]; then
      # shellcheck disable=SC1091
      codename="$(. /etc/os-release && printf '%s' "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
    fi
    printf '%b\n' "Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: $codename\nComponents: stable\nArchitectures: $(dpkg --print-architecture)\nSigned-By: /etc/apt/keyrings/docker.asc" |
      sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null
    apt_get_update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  if ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    sudo usermod -aG docker "$USER"
    warning "Docker group added; log out and back in before using Docker without sudo"
  fi
  check
}

install_ghcli() {
  if exists gh || package_installed gh; then
    warning "GH-CLI already installed, skipping"
    return
  fi

  step "Installing GH-CLI"
  local temp_dir
  temp_dir="$(mktemp -d)"
  TEMP_PATHS+=("$temp_dir")

  sudo install -m 0755 -d /etc/apt/keyrings
  download_file "https://cli.github.com/packages/githubcli-archive-keyring.gpg" "$temp_dir/githubcli-archive-keyring.gpg"
  sudo install -m 0644 "$temp_dir/githubcli-archive-keyring.gpg" /etc/apt/keyrings/githubcli-archive-keyring.gpg
  printf '%s\n' "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
    sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  apt_get_update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gh
  check
}

install_bitwarden() {
  if exists bitwarden || package_installed bitwarden; then
    warning "Bitwarden already installed, skipping"
    return
  fi

  step "Installing Bitwarden"
  local package_file
  package_file="$(mktemp --suffix=.deb)"
  TEMP_PATHS+=("$package_file")
  download_file "https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb" "$package_file"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$package_file"
  check
}

install_npm_packages() {
  local package
  local -a packages=(yarn pnpm npm-check-updates neovim prettier)

  step "Installing npm packages"
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] || {
    warning "NVM is not available, skipping npm packages"
    return
  }
  # shellcheck disable=SC1090,SC1091
  source "$NVM_DIR/nvm.sh"
  if exists corepack; then
    corepack enable
  fi

  for package in "${packages[@]}"; do
    if npm list --global --depth=0 "$package" >/dev/null 2>&1; then
      warning "npm package $package already installed, skipping"
    else
      npm install --global "$package"
    fi
  done
  check
}

install_fonts() {
  mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
  step "Installing Nerd Font"
  bash "$SCRIPT_DIR/nerdfont_install.sh" "$@"
  check
}

install_fzf() {
  if [[ -d "$HOME/.fzf" ]] || exists fzf; then
    warning "fzf already installed, skipping"
    return
  fi

  step "Installing fzf"
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --all
  check
}

adjust_clock() {
  step "Configure date to use Local Time"
  if ! exists timedatectl; then
    warning "timedatectl not found, skipping RTC adjustment"
    return
  fi

  if ! sudo timedatectl set-local-rtc 1 --adjust-system-clock 2>/dev/null; then
    warning "Unable to set local RTC (timedatectl unavailable or not supported in this environment), skipping"
    return
  fi
  check
}

configure_dotfiles() {
  step "Fetching dotfiles"
  if [[ ! -d "$HOME/dotfiles" ]]; then
    git clone https://github.com/verzola/dotfiles.git "$HOME/dotfiles"
  else
    git -C "$HOME/dotfiles" pull origin main
  fi

  if exists make && [[ -f "$HOME/dotfiles/Makefile" ]]; then
    make -C "$HOME/dotfiles"
  fi
  check
}

configure_zsh() {
  step "Changing default shell to zsh"
  local zsh_path
  zsh_path="$(command -v zsh || true)"
  if [[ -z "$zsh_path" ]]; then
    warning "zsh is not installed, skipping"
    return
  fi

  local current_shell
  current_shell="$(getent passwd "$USER" | cut -d: -f7)"
  if [[ "$current_shell" == "$zsh_path" ]]; then
    warning "Default shell is already zsh, skipping"
    return
  fi

  sudo chsh -s "$zsh_path" "$USER"
  check
}

tweak_inotify() {
  step "Tweaking inotify"
  local target_conf="/etc/sysctl.d/60-inotify.conf"
  printf '%s\n' 'fs.inotify.max_user_watches=524288' | sudo tee "$target_conf" >/dev/null
  sudo sysctl -p "$target_conf" >/dev/null 2>&1 || sudo sysctl --system >/dev/null 2>&1 || true
  if [[ -r /proc/sys/fs/inotify/max_user_watches ]]; then
    cat /proc/sys/fs/inotify/max_user_watches
  fi
  check
}

add_to_sudoers() {
  step "Adding user to sudoers group"
  if id -nG "$USER" | tr ' ' '\n' | grep -qx sudo; then
    warning "User already in sudo group, skipping"
  else
    sudo usermod -aG sudo "$USER"
    check
  fi
}

report_version() {
  local label="$1"
  local command_name="$2"
  local output
  shift 2

  if ! exists "$command_name"; then
    printf '%-18s %s\n' "$label:" 'not installed'
    return
  fi

  output="$($command_name "$@" 2>&1 || true)"
  printf '%-18s %s\n' "$label:" "$(printf '%s\n' "$output" | sed -n '1p')"
}

show_summary() {
  step "Installed versions"
  report_version Git git --version
  report_version Node node --version
  report_version npm npm --version
  report_version pnpm pnpm --version
  report_version Python python3 --version
  report_version VSCode code --version
  report_version Antigravity antigravity --version
  report_version AntigravityCLI agy --version
  report_version Docker docker --version
  report_version Compose docker compose version
  report_version GitHubCLI gh --version
  report_version Neovim nvim --version
  report_version Starship starship --version
  report_version fzf fzf --version
  report_version SSH ssh -V
  printf 'Log: %s\n' "$LOG_FILE"
}

usage() {
  printf 'Usage: %s [step [args...]]\n' "$(basename "$0")"
  printf 'Run without an argument to execute the default setup.\n'
  printf 'Use --list to show available setup steps.\n'
}

STEPS=(
  update_system
  install_packages
  create_folders
  configure_git
  configure_ssh
  install_vscode
  install_antigravity
  install_antigravity_cli
  install_brave
  install_nvm
  install_npm_packages
  install_starship
  install_fzf
  install_neovim
  install_docker
  install_bitwarden
  install_ghcli
  adjust_clock
  configure_dotfiles
  configure_zsh
  tweak_inotify
  add_to_sudoers
  cleanup_packages
  install_fonts
  show_summary
)

list_steps() {
  printf '%s\n' "${STEPS[@]}"
}

is_valid_step() {
  local target="$1"
  local s
  for s in "${STEPS[@]}"; do
    if [[ "$s" == "$target" ]]; then
      return 0
    fi
  done
  return 1
}

setup() {
  case "${1:-}" in
    --help | -h)
      usage
      return 0
      ;;
    --list)
      list_steps
      return 0
      ;;
  esac

  if [[ -z "${1:-}" ]]; then
    init_logging
    printf "\nVerzola's Ubuntu Setup\n"
    validate_environment
    local current_step
    for current_step in "${STEPS[@]}"; do
      "$current_step"
    done
    printf '\nFinished!\n'
  else
    local step_name="$1"
    if ! is_valid_step "$step_name"; then
      printf 'Unknown setup step: %s\n' "$step_name" >&2
      printf 'Use --list to see available steps.\n' >&2
      exit 2
    fi
    shift
    init_logging
    printf "\nVerzola's Ubuntu Setup\n"
    validate_environment
    "$step_name" "$@"
  fi
}

setup "$@"
