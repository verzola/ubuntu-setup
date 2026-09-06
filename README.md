# ubuntu-setup

Scripts to set up an Ubuntu desktop with the packages and tools used in this environment.

## Usage

Run the setup as a regular user with `sudo` access:

```bash
./setup.sh
```

Use `./setup.sh --help` for usage information or `./setup.sh --list` to list individual setup steps. A step can be run directly, for example:

```bash
./setup.sh install_packages
```

The default flow ends with an interactive Nerd Font selection. The script can be started from any directory; paths are resolved relative to the project directory.

The installation is idempotent: existing APT, Visual Studio Code, Node.js, npm, Python, Docker Compose, Neovim and font installations are skipped.

Before installing, the script validates the operating system, architecture, sudo access and internet connection. The execution log is saved at `~/.local/state/ubuntu-setup/setup.log`.

The default setup also prepares Git, optionally creates an Ed25519 SSH key for GitHub, installs common development tools, configures Node.js with npm/pnpm, adds the user to the Docker group, and prints installed tool versions at the end.
