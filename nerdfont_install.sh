#!/usr/bin/env bash
set -Eeuo pipefail

install_file="$(mktemp)"
trap 'rm -f "$install_file"' EXIT

curl --fail --silent --show-error --location \
  https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/install.sh \
  --output "$install_file"

bash "$install_file" install
