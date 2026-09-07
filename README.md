# ubuntu-setup

Scripts to set up an Ubuntu desktop with the packages and tools used in this environment.

## Usage

Run the setup as a regular user with `sudo` access:

```bash
./setup.sh
```

Use `./setup.sh --help` for usage information or `./setup.sh --list` to list available setup steps. A step can be run directly, optionally with arguments:

```bash
./setup.sh install_packages
./setup.sh install_fonts JetBrainsMono
```

The default flow ends with a Nerd Font installation (interactive in a terminal, or specific font names can be provided). The script can be started from any directory; paths are resolved relative to the project directory.

The installation is idempotent: existing APT packages, Visual Studio Code, Antigravity, Node.js, npm packages, Python, Docker, Neovim, and fonts are detected and skipped if already installed.

Before installing, the script validates the operating system, architecture, sudo access and internet connection. Execution logs are saved to `~/.local/state/ubuntu-setup/setup.log`.

The default setup also prepares Git, optionally creates an Ed25519 SSH key for GitHub, configures user bin folders and standard symlinks (`bat`, `fd`), configures Node.js with npm/pnpm, configures sysctl watchers cleanly under `/etc/sysctl.d/60-inotify.conf`, adds the user to the Docker group, and prints installed tool versions at the end.

