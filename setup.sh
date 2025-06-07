#!/bin/bash

set -e  # Exit on error

REPO_URL="git@github.com:WenkaiQin/dotfiles.git"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES_TO_LINK=(
  ".zshrc"
  "agkozak-zsh-prompt.plugin.zsh"
)

# Backup function
backup_file() {
  local file="$1"
  if [ -f "$file" ] || [ -L "$file" ]; then
    mv "$file" "${file}.bak.$(date +%s)"
    echo "Backed up existing $file"
  fi
}

# Clone dotfiles repo
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo "Cloning dotfiles repo..."
  git clone "$REPO_URL" "$DOTFILES_DIR"
else
  echo "Dotfiles repo already exists, pulling latest changes..."
  git -C "$DOTFILES_DIR" pull
fi

# Link files
for filename in "${FILES_TO_LINK[@]}"; do
  target="$HOME/$filename"
  source="$DOTFILES_DIR/$filename"

  if [ ! -e "$source" ]; then
    echo "Warning: $source does not exist. Skipping."
    continue
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    backup_file "$target"
  fi

  ln -s "$source" "$target"
  echo "Linked $target -> $source"
done

echo "✅ Dotfiles setup complete."