#!/usr/bin/env bash

set -e

# Update package lists and install required dependencies
echo "🔧 Installing dependencies..."
sudo apt update
sudo apt install -y dconf-cli uuid-runtime wget curl

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
    echo $NAME
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
