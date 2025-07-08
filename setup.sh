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
  # "agkozak-zsh-prompt.plugin.zsh" # No longer used, replaced by pure
  ".gitignore_global"
  ".gitconfig"
)

# Backup an existing file.
backup_file() {
  local file="$1"
  if [ -f "$file" ] || [ -L "$file" ]; then
    mv "$file" "${file}.bak.$(date +%s)"
    echo "🔁 Backed up existing $file"
  fi
}

# Install base packages.
install_packages() {
  echo "📦 Installing required packages..."


  if [[ "$platform" == "linux" ]]; then
    REQUIRED_PKGS=(zsh git curl)
    sudo apt update
    for pkg in "${REQUIRED_PKGS[@]}"; do
      if dpkg -s "$pkg" &>/dev/null; then
        echo "✅ $pkg already installed"
      else
        echo "📦 Installing $pkg..."
        sudo apt install -y "$pkg"
      fi
    done

  elif [[ "$platform" == "mac" ]]; then
    REQUIRED_PKGS=(git curl)
    if ! command -v brew &>/dev/null; then
      echo "🍺 Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    for pkg in "${REQUIRED_PKGS[@]}"; do
      if brew list "$pkg" &>/dev/null; then
        echo "✅ $pkg already installed"
      else
        echo "📦 Installing $pkg..."
        brew install "$pkg"
      fi
    done
  fi
}

# Install fzf
install_fzf() {
  echo "🔍 Installing fzf..."
  if command -v fzf &>/dev/null; then
    echo "✅ fzf already installed"
  else
    brew install fzf
  fi
  # Run the optional install script for keybindings and completion
  FZF_INSTALL_SCRIPT="$(brew --prefix)/opt/fzf/install"
  if [[ -x "$FZF_INSTALL_SCRIPT" ]]; then
    echo "⚙️  Setting up fzf key bindings and completions..."
    "$FZF_INSTALL_SCRIPT" --key-bindings --completion --no-update-rc  &>/dev/null
  else
    echo "⚠️  fzf install script not found at $FZF_INSTALL_SCRIPT"
  fi
}

# Install zsh plugins
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

# Install Snazzy theme
install_snazzy_theme() {
    echo "🎨 Installing Snazzy terminal theme..."

    if [ "$platform" = "mac" ]; then
        echo "🧠 macOS detected — using Terminal.app installer"
        bash "$DOTFILES_DIR/install_snazzy_mac.sh"
    elif [ "$platform" = "linux" ]; then
        echo "🧠 Linux detected — using GNOME Terminal installer"
        bash "$DOTFILES_DIR/install_snazzy_gnome.sh"
    else
        echo "⚠️ Unsupported platform for Snazzy installation."
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

# Ensure Zsh completion cache directory exists
ZSH_CACHE_DIR="$HOME/.zsh/cache"
if [ ! -d "$ZSH_CACHE_DIR" ]; then
  echo "📂 Creating Zsh completion cache directory at $ZSH_CACHE_DIR"
  mkdir -p "$ZSH_CACHE_DIR"
else
  echo "✅ Zsh completion cache directory already exists"
fi

# Install packages, plugins, and fzf
install_packages
install_zsh_plugins
install_fzf
install_snazzy_theme

# Ensure ~/.gitconfig.local exists with user identity
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  echo "🧾 Setting up ~/.gitconfig.local (Git identity for this machine):"
  read -r -p "  Git user.name: " git_name
  read -r -p "  Git user.email: " git_email

  cat > "$HOME/.gitconfig.local" <<EOF
[user]
    name = $git_name
    email = $git_email
EOF

  echo "✅ ~/.gitconfig.local created."
fi

# Change shell to Zsh
ZSH_PATH="$(command -v zsh)"
if [ "$SHELL" != "$ZSH_PATH" ]; then
  echo "🌀 Changing default shell to Zsh ($ZSH_PATH)..."
  chsh -s "$ZSH_PATH"
fi

echo "✅ Dotfiles setup complete."
echo "📎 Restart your terminal or run: exec $ZSH_PATH"