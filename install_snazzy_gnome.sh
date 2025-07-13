#!/usr/bin/env bash

set -e

FORCE=false
if [[ "$1" == "--force" ]]; then
    FORCE=true
    echo "🔁 Force mode enabled — reinstalling Snazzy theme."
fi

# Check for existing Snazzy profile first
echo "🔍 Checking for existing Snazzy GNOME Terminal profile..."
EXISTING_UUID=""
PROFILE_LIST=$(gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[],'")

for PROFILE_ID in $PROFILE_LIST; do
    NAME=$(gsettings get "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" visible-name | tr -d "'")
    if [[ "$NAME" == "Snazzy" ]]; then
        EXISTING_UUID="$PROFILE_ID"
        break
    fi
done

if [[ -n "$EXISTING_UUID" && "$FORCE" == false ]]; then
    echo "✅ Snazzy profile already exists (UUID: $EXISTING_UUID). Skipping installation."
    echo "ℹ️  Use './install_snazzy_gnome.sh --force' to reinstall."
    gsettings set org.gnome.Terminal.ProfilesList default "$EXISTING_UUID"
    exit 0
fi

if [[ -n "$EXISTING_UUID" && "$FORCE" == true ]]; then
    echo "🔁 Reinstalling Snazzy theme after forced removal..."
    echo "🗑️  Removing existing Snazzy profile (UUID: $EXISTING_UUID)..."
    dconf reset -f "/org/gnome/terminal/legacy/profiles:/:$EXISTING_UUID/"
    gsettings set org.gnome.Terminal.ProfilesList list "[$(gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[]'" | sed "s/\b$EXISTING_UUID\b//g" | xargs | sed 's/ /, /g')]"
fi

# Update package lists and install required dependencies
echo "🔧 Installing dependencies..."
if command -v apt &>/dev/null; then
    sudo apt update
    sudo apt install -y dconf-cli uuid-runtime wget curl
elif command -v dnf &>/dev/null; then
    sudo dnf install -y dconf uuid wget curl
elif command -v yum &>/dev/null; then
    sudo yum install -y dconf uuid wget curl
else
    echo "❌ Unsupported package manager. Please install: dconf, uuid-runtime, wget, and curl manually."
    exit 1
fi

# Download and run the Gogh installer script, selecting the 'Snazzy' theme
echo "🎨 Installing Snazzy theme for GNOME Terminal using Gogh..."
(
    sleep 5
    echo "291"
) | bash -c "$(wget -qO- https://git.io/vQgMr)"

# Give GNOME Terminal some time to register the new profile
sleep 1

# Find the UUID of the newly created Snazzy profile
echo "🔍 Searching for the Snazzy profile UUID..."
PROFILE_LIST=$(gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[],'")

for PROFILE_ID in $PROFILE_LIST; do
    NAME=$(gsettings get "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" visible-name)
    if [[ $NAME == *"Snazzy"* ]]; then
        SNAZZY_UUID=$PROFILE_ID
        break
    fi
done

# Exit if the Snazzy profile was not found
if [ -z "$SNAZZY_UUID" ]; then
    echo "❌ Could not find the Snazzy profile. Make sure the theme script ran correctly."
    exit 1
fi

# Set Snazzy as the default GNOME Terminal profile
echo "✅ Found Snazzy profile: $SNAZZY_UUID"
echo "📌 Setting Snazzy as the default GNOME Terminal profile..."
gsettings set org.gnome.Terminal.ProfilesList default "$SNAZZY_UUID"

echo "🖋️ Setting font to Monospace 12..."
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$SNAZZY_UUID/" font 'Monospace 12'
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$SNAZZY_UUID/" use-system-font false

echo "🎉 Done! Open GNOME Terminal and enjoy the Snazzy theme."
