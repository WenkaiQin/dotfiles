#!/bin/bash

set -e

echo "🛠️  Starting dotfiles setup..."

# Determine OS type
OS_TYPE="$(uname -s)"
case "$OS_TYPE" in
    Linux*)     platform=linux;;
    Darwin*)    platform=mac;;
    *)          echo "Unsupported platform: $OS_TYPE"; exit 1;;
esac
echo "Detected platform: $platform"

# Set up dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FILES_TO_LINK=(
  ".zshrc"
  "agkozak-zsh-prompt.plugin.zsh"
)

# Backup existing files
backup_file() {
  local file="$1"
  if [ -f "$file" ] || [ -L "$file" ]; then
    mv "$file" "${file}.bak.$(date +%s)"
    echo "🔁 Backed up existing $file"
  fi
}

# Install base packages
install_packages() {
  echo "📦 Installing required packages..."
  if [ "$platform" = "linux" ]; then
    sudo apt update && sudo apt install -y zsh git curl
  elif [ "$platform" = "mac" ]; then
    if ! command -v brew >/dev/null; then
      echo "🍺 Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install zsh git curl
  fi
}

# Install Zsh plugins
install_zsh_plugins() {
  mkdir -p ~/.zsh

  if [ ! -d "${HOME}/.zsh/zsh-syntax-highlighting" ]; then
    echo "✨ Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${HOME}/.zsh/zsh-syntax-highlighting"
  fi

  if [ ! -d "${HOME}/.zsh/zsh-autosuggestions" ]; then
    echo "💡 Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.zsh/zsh-autosuggestions"
  fi
  # Install Pure prompt
  if [ "$platform" = "mac" ]; then
    if ! brew list pure &>/dev/null; then
      echo "🌟 Installing pure via Homebrew..."
      brew install pure
    fi
  else
    if [ ! -d "${HOME}/.zsh/pure" ]; then
      echo "🌟 Installing pure prompt manually..."
      git clone https://github.com/sindresorhus/pure.git "${HOME}/.zsh/pure"
    fi
  fi
}

# Symlink dotfiles
for filename in "${FILES_TO_LINK[@]}"; do
  target="$HOME/$filename"
  source="$DOTFILES_DIR/$filename"

  if [ ! -e "$source" ]; then
    echo "⚠️  Warning: $source not found. Skipping."
    continue
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    backup_file "$target"
  fi

  ln -s "$source" "$target"
  echo "🔗 Linked $target → $source"
done

# Install packages and plugins
install_packages
install_zsh_plugins

# Change shell to Zsh
ZSH_PATH="$(command -v zsh)"
if [ "$SHELL" != "$ZSH_PATH" ]; then
  echo "🌀 Changing default shell to Zsh ($ZSH_PATH)..."
  chsh -s "$ZSH_PATH"
fi

echo "✅ Dotfiles setup complete."
echo "📎 Restart your terminal or run: exec $ZSH_PATH"