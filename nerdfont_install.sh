#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  printf 'Usage: %s [FontName...]\n' "$(basename "$0")"
  printf 'Run without arguments in an interactive terminal to select fonts interactively.\n'
}

case "${1:-}" in
  --help | -h)
    usage
    exit 0
    ;;
esac

fonts_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
mkdir -p "$fonts_dir"

install_file="$(mktemp)"
trap 'rm -f "$install_file"' EXIT

curl --fail --silent --show-error --location \
  https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/install.sh \
  --output "$install_file"

if [[ $# -gt 0 ]]; then
  bash "$install_file" install "$@"
elif [[ -t 0 ]]; then
  bash "$install_file" install
else
  printf 'No interactive terminal detected; skipping Nerd Font selection.\n'
fi
