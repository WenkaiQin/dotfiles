#!/usr/bin/env bash

set -e

echo "🔧 Installing dependencies..."
sudo apt update
sudo apt install -y dconf-cli uuid-runtime wget curl

echo "🎨 Installing Snazzy theme for GNOME Terminal using Gogh..."
export TERMINAL=gnome-terminal
bash -c "$(wget -qO- https://raw.githubusercontent.com/Mayccoll/Gogh/master/themes/snazzy.sh)"

# Wait briefly to let profile register
sleep 1

echo "🔍 Searching for the Snazzy profile UUID..."
PROFILE_LIST=$(gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[],'")

for PROFILE_ID in $PROFILE_LIST; do
    NAME=$(gsettings get "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" visible-name)
    if [[ $NAME == *"Snazzy"* ]]; then
        SNAZZY_UUID=$PROFILE_ID
        break
    fi
done

if [ -z "$SNAZZY_UUID" ]; then
    echo "❌ Could not find the Snazzy profile. Make sure the theme script ran correctly."
    exit 1
fi

echo "✅ Found Snazzy profile: $SNAZZY_UUID"
echo "📌 Setting Snazzy as the default GNOME Terminal profile..."
gsettings set org.gnome.Terminal.ProfilesList default "$SNAZZY_UUID"

echo "🎉 Done! Open GNOME Terminal and enjoy the Snazzy theme."