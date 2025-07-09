#!/usr/bin/env bash

set -e

FORCE=false
if [[ "$1" == "--force" ]]; then
    FORCE=true
    echo "🔁 Force mode enabled — will reinstall Snazzy theme."
fi

PLATFORM="$(uname)"

case "$PLATFORM" in
Darwin)
    echo "🧠 macOS detected — configuring Terminal.app..."

    THEME_NAME="Snazzy"
    PLIST="$HOME/Library/Preferences/com.apple.Terminal.plist"

    if /usr/libexec/PlistBuddy -c "Print 'Window Settings':$THEME_NAME" "$PLIST" &>/dev/null && [[ "$FORCE" == false ]]; then
        echo "✅ Terminal profile '$THEME_NAME' already exists. Skipping installation."
        exit 0
    fi

    THEME_URL="https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/terminal/Snazzy.terminal"
    TMP_DIR=$(mktemp -d)
    THEME_PATH="$TMP_DIR/Snazzy.terminal"

    echo "🎨 Downloading Snazzy theme for Terminal.app..."
    curl -fsSL -o "$THEME_PATH" "$THEME_URL"

    echo "📂 Importing theme..."
    open "$THEME_PATH"
    sleep 2

    echo "📌 Applying theme to all windows..."
    osascript <<EOF
    if application "Terminal" is not running then
        tell application "Terminal" to activate
    end if
    tell application "Terminal"
        set default settings to settings set "$THEME_NAME"
        set startup settings to settings set "$THEME_NAME"
        repeat with w in windows
            repeat with t in tabs of w
                set current settings of t to settings set "$THEME_NAME"
            end repeat
        end repeat
    end tell
EOF

    echo "🖋️ Setting font to Menlo 12pt..."
    osascript <<EOF
    tell application "Terminal"
        set font name of settings set "$THEME_NAME" to "Menlo-Regular"
        set font size of settings set "$THEME_NAME" to 12
    end tell
EOF

    rm -rf "$TMP_DIR"
    echo "🎉 Snazzy theme applied to Terminal.app!"

    ;;

Linux)
    echo "🧠 Linux detected — configuring GNOME Terminal..."

    echo "🔧 Installing dependencies..."
    sudo apt update
    sudo apt install -y dconf-cli uuid-runtime wget curl

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
        gsettings set org.gnome.Terminal.ProfilesList default "$EXISTING_UUID"
        exit 0
    fi

    if [[ -n "$EXISTING_UUID" && "$FORCE" == true ]]; then
        echo "🔁 Reinstalling Snazzy theme after forced removal..."
        dconf reset -f "/org/gnome/terminal/legacy/profiles:/:$EXISTING_UUID/"
        UPDATED_LIST=$(echo "$PROFILE_LIST" | tr ' ' '\n' | grep -v "^$EXISTING_UUID$" | paste -sd, -)
        gsettings set org.gnome.Terminal.ProfilesList list "[$UPDATED_LIST]"
    fi

    echo "🎨 Installing Snazzy via Gogh..."
    (
        sleep 5
        echo "291"
    ) | bash -c "$(wget -qO- https://git.io/vQgMr)"
    sleep 1

    PROFILE_LIST=$(gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[],'")
    for PROFILE_ID in $PROFILE_LIST; do
        NAME=$(gsettings get "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/" visible-name)
        if [[ $NAME == *"Snazzy"* ]]; then
            SNAZZY_UUID=$PROFILE_ID
            break
        fi
    done

    if [ -z "$SNAZZY_UUID" ]; then
        echo "❌ Snazzy profile not found after install."
        exit 1
    fi

    echo "📌 Setting Snazzy as the default profile..."
    gsettings set org.gnome.Terminal.ProfilesList default "$SNAZZY_UUID"

    echo "🖋️ Setting font to Monospace 12..."
    gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$SNAZZY_UUID/" font 'Monospace 12'
    gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$SNAZZY_UUID/" use-system-font false

    echo "🎉 Snazzy theme applied to GNOME Terminal!"
    ;;

*)
    echo "❌ Unsupported platform: $PLATFORM"
    exit 1
    ;;
esac