# Dotfiles Setup

This repository contains Wenkai's personal dotfiles and helper scripts for configuring
Zsh, Git, and terminal themes on macOS and Linux.

The main entry point is **`setup.sh`** which detects your operating system and performs
these tasks:

1. Installs required packages (`zsh`, `git`, `curl` and Homebrew on macOS).
2. Installs Zsh plugins (pure prompt, zsh-autosuggestions and zsh-syntax-highlighting).
3. Applies the "Snazzy" terminal theme using `install_snazzy.sh`.
4. Installs [fzf](https://github.com/junegunn/fzf) with key bindings and completion.
5. Symlinks dotfiles from this repo to your home directory (`.zshrc`, `.gitconfig`,
   `.gitignore_global`). Existing files are backed up with a timestamp suffix.
6. Creates `~/.gitconfig.local` for your personal Git name and email if it does not exist.
7. Changes your default shell to Zsh.

To undo the changes run `./setup.sh uninstall` which removes the symlinks,
plugins and theme.

Additional scripts include:

- `install_snazzy.sh` – Cross-platform installer for the Snazzy terminal theme.
  Platform specific versions (`install_snazzy_gnome.sh` and `install_snazzy_mac.sh`)
  are provided for manual use.
- `setup_ssh_linux.sh` – Installs and optionally hardens OpenSSH on Ubuntu/Debian.

## Usage

Clone the repository and execute the setup script:

```bash
./setup.sh
```

The script will print progress messages and prompt for your Git identity when
creating `~/.gitconfig.local`. After completion restart your terminal or run
`exec $(which zsh)` to start using the new configuration.
