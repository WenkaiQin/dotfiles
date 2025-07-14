#!/bin/bash
set -e

echo "🛠️  Starting dotfiles setup..."

# Determine OS type
OS_TYPE="$(uname -s)"
if [ -f /etc/redhat-release ]; then
    platform=redhat
else
    case "$OS_TYPE" in
        Linux*)     platform=linux;;
        Darwin*)    platform=mac;;
        *)          echo "Unsupported platform: $OS_TYPE"; exit 1;;
    esac
fi

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
    PKG_MGR="apt"
    INSTALL_CMD="sudo apt install -y"
    sudo apt update

  elif [[ "$platform" == "redhat" ]]; then

    PKG_MGR=$(command -v dnf &>/dev/null && echo "dnf" || echo "yum")
    INSTALL_CMD="sudo $PKG_MGR install -y"
    sudo $PKG_MGR -y makecache

  elif [[ "$platform" == "mac" ]]; then
    REQUIRED_PKGS=(git curl)  # zsh is preinstalled and managed separately on macOS
    if ! command -v brew &>/dev/null; then
      echo "🍺 Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    PKG_MGR="brew"
    INSTALL_CMD="brew install"
  fi

  for pkg in "${REQUIRED_PKGS[@]}"; do
    if command -v "$pkg" &>/dev/null; then
      echo "✅ $pkg already installed"
    else
      echo "📦 Installing $pkg..."
      $INSTALL_CMD "$pkg"
    fi
  done

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

    echo ""
    echo "💡 Terminal.app tips:"
    echo "   • Enable 'Use Option as Meta':"
    echo "     Terminal → Preferences → Profile → Keyboard → ✅ Use Option as Meta Key"
    echo "   • Customize window title:"
    echo "     Terminal → Preferences → Profile → Window → Title: Working Directory"
    echo "   • You may also want to disable the audible bell in Terminal → Settings → Advanced"
    read -n 1 -r -s -p $'Press any key once you’ve reviewed these suggestions...\n'
    echo ""

  elif [[ "$platform" == "linux" || "$platform" == "redhat" ]]; then
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
# Install zsh plugins
install_zsh_plugins() {
  mkdir -p ~/.zsh

  echo "🔌 Installing Zsh plugins..."

  if [[ "$platform" == "mac" ]]; then
    # Install zsh-syntax-highlighting via Homebrew
    if brew list zsh-syntax-highlighting &>/dev/null; then
      echo "✅ zsh-syntax-highlighting already installed via Homebrew"
    else
      echo "✨ Installing zsh-syntax-highlighting via Homebrew..."
      brew install zsh-syntax-highlighting
    fi

    # Install zsh-autosuggestions via Homebrew
    if brew list zsh-autosuggestions &>/dev/null; then
      echo "✅ zsh-autosuggestions already installed via Homebrew"
    else
      echo "💡 Installing zsh-autosuggestions via Homebrew..."
      brew install zsh-autosuggestions
    fi

    # Install pure via Homebrew
    if brew list pure &>/dev/null; then
      echo "✅ pure prompt already installed via Homebrew"
    else
      echo "🌟 Installing pure prompt via Homebrew..."
      brew install pure
    fi

  else
    # Install manually on Linux/RedHat

    if [ ! -d "${HOME}/.zsh/zsh-syntax-highlighting" ]; then
      echo "✨ Installing zsh-syntax-highlighting..."
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${HOME}/.zsh/zsh-syntax-highlighting"
    else
      echo "✅ zsh-syntax-highlighting already installed"
    fi

    if [ ! -d "${HOME}/.zsh/zsh-autosuggestions" ]; then
      echo "💡 Installing zsh-autosuggestions..."
      git clone https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.zsh/zsh-autosuggestions"
    else
      echo "✅ zsh-autosuggestions already installed"
    fi

    if [ ! -d "${HOME}/.zsh/pure" ]; then
      echo "🌟 Installing pure prompt manually..."
      git clone https://github.com/sindresorhus/pure.git "${HOME}/.zsh/pure"
    else
      echo "✅ pure prompt already installed"
    fi
  fi
}

# Install Snazzy theme (unified script)
install_snazzy_theme() {
    echo "🎨 Installing Snazzy terminal theme..."
    if ! bash "$DOTFILES_DIR/install_snazzy.sh"; then
        echo "⚠️  Warning: Snazzy theme installation failed or was skipped. You can try again by running install_snazzy."
    fi
}

# Uninstall option.
if [[ "$1" == "uninstall" ]]; then
    echo "⚠️  Starting dotfiles uninstall..."

    echo "📌 NOTE: This will NOT uninstall core packages (git, zsh, curl) or Homebrew itself."
    echo "🧹 It will remove:"
    echo "   • Dotfile symlinks (if managed by this script)"
    echo "   • Zsh plugins (manual installs on Linux/RedHat, Homebrew installs on macOS)"
    echo "   • fzf (via Homebrew on macOS or manually cloned on Linux)"
    echo "   • Snazzy terminal theme (partially — manual cleanup may still be needed)"
    echo ""

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

    # Function to safely attempt Homebrew uninstall
    brew_uninstall() {
      local pkg="$1"
      if brew list "$pkg" &>/dev/null; then
        echo "🔧 Uninstalling $pkg..."
        if brew uninstall "$pkg" &>/dev/null; then
          echo "✅ Uninstalled $pkg"
        else
          echo "⚠️  Could not uninstall $pkg — possibly required by another package"
        fi
      fi
    }

    echo "🧹 Removing Zsh plugins..."

    if [[ "$platform" == "mac" ]]; then
        brew_uninstall zsh-syntax-highlighting
        brew_uninstall zsh-autosuggestions
        brew_uninstall pure
    else
        rm -rf ~/.zsh/zsh-syntax-highlighting ~/.zsh/zsh-autosuggestions ~/.zsh/pure
        echo "✅ Removed manually-installed Zsh plugins"
    fi

    echo "🧹 Removing fzf..."
    if [[ "$platform" == "linux" || "$platform" == "redhat" ]]; then
        rm -rf ~/.fzf
        echo "⚠️  GNOME Terminal theme was not automatically reverted."
        echo "📝 To remove Snazzy: open GNOME Terminal → Preferences → Profiles and switch to a different theme or delete the Snazzy profile manually."
    elif [[ "$platform" == "mac" ]]; then
        brew_uninstall fzf
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
