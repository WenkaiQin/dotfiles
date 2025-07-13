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
    sudo apt-get update -y
    for pkg in "${REQUIRED_PKGS[@]}"; do
      if command -v "$pkg" &>/dev/null; then
        echo "✅ $pkg already installed"
      else
        echo "📦 Installing $pkg..."
        sudo apt-get install -y "$pkg"
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

  if [[ "$platform" == "mac" ]]; then
    if command -v fzf &>/dev/null; then
      echo "✅ fzf already installed"
    else
      brew install fzf
    fi

    FZF_INSTALL_SCRIPT="$(brew --prefix)/opt/fzf/install"
    if [[ -x "$FZF_INSTALL_SCRIPT" ]]; then
      echo "⚙️  Setting up fzf key bindings and completions..."
      "$FZF_INSTALL_SCRIPT" --key-bindings --completion --no-update-rc &>/dev/null
    else
      echo "⚠️  fzf install script not found at $FZF_INSTALL_SCRIPT"
    fi

    echo "⚠️  IMPORTANT: Enable 'Use Option as Meta' in Terminal.app:"
    echo "  Terminal → Preferences → Profile → Keyboard → Check 'Use Option as Meta Key'"
    read -n 1 -r -s -p $'Press any key once done...\n'

  elif [[ "$platform" == "linux" ]]; then
    if [ -d "$HOME/.fzf" ]; then
      echo "🔁 Updating existing ~/.fzf..."
      (cd "$HOME/.fzf" && git pull)
    else
      echo "⬇️  Cloning fzf..."
      git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    fi

    echo "⚙️  Running fzf install script for key bindings and completions..."
    ~/.fzf/install --key-bindings --completion --no-update-rc &>/dev/null
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


# Install Snazzy theme (unified script)
install_snazzy_theme() {
    echo "🎨 Installing Snazzy terminal theme..."
    bash "$DOTFILES_DIR/install_snazzy.sh"
}

# Uninstall option.
if [[ "$1" == "uninstall" ]]; then
    echo "⚠️  Starting dotfiles uninstall..."

    for filename in "${FILES_TO_LINK[@]}"; do
        target="$HOME/$filename"
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$DOTFILES_DIR/"* ]]; then
            echo "❌ Removing symlink: $target"
            rm "$target"
            if ls "$target".bak.* &>/dev/null; then
                latest_backup=$(ls "$target".bak.* | sort | tail -n 1)
                echo "🔁 Restoring backup: $latest_backup → $target"
                mv "$latest_backup" "$target"
            fi
        fi
    done

    echo "🧹 Removing Zsh plugins..."
    rm -rf ~/.zsh/zsh-syntax-highlighting ~/.zsh/zsh-autosuggestions ~/.zsh/pure

    echo "🧹 Removing fzf..."
    if [[ "$platform" == "linux" ]]; then
        rm -rf ~/.fzf
        echo "⚠️  GNOME Terminal theme was not automatically reverted."
        echo "📝 To remove Snazzy: open GNOME Terminal → Preferences → Profiles and switch to a different theme or delete the Snazzy profile manually."
    elif [[ "$platform" == "mac" ]]; then
        brew uninstall fzf &>/dev/null || true
        brew uninstall pure &>/dev/null || true
        echo "⚠️  Terminal theme was not automatically reverted."
        echo "📝 To remove Snazzy: open Terminal → Settings → Profiles and switch or delete manually."
    fi


    echo "❌ Dotfiles uninstallation complete."
    exit 0
fi

# Install packages, zshplugins, and fzf
install_packages
install_zsh_plugins
install_snazzy_theme
install_fzf

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

  ln -sf "$source" "$target"
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
if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "⚠️  $ZSH_PATH is not in /etc/shells. You may need to add it manually, otherwise chsh will fail silently."
fi

if [ "$SHELL" != "$ZSH_PATH" ]; then
  LOGIN_USER="$(whoami)"
  if ! grep -q "^$LOGIN_USER:" /etc/passwd; then
    echo "⚠️  Skipping chsh: user '$LOGIN_USER' not found in /etc/passwd. You may need to change shell manually."
  else
    echo "🌀 Changing default shell to Zsh ($ZSH_PATH) for user $LOGIN_USER..."
    chsh -s "$ZSH_PATH" "$LOGIN_USER"
  fi
fi

echo "✅ Dotfiles setup complete."
echo "📎 Restart your terminal or run: exec $ZSH_PATH"
