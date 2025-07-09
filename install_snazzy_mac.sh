#!/usr/bin/env bash

set -e

echo "🔧 Checking OS..."
echo "OSTYPE is: '$OSTYPE'"
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This script is for macOS Terminal.app only."
    exit 1
fi

# Don't install if the theme already exists.
THEME_NAME="Snazzy"
PLIST="$HOME/Library/Preferences/com.apple.Terminal.plist"

FORCE=false
if [[ "$1" == "--force" ]]; then
    FORCE=true
    echo "🔁 Force mode enabled — will reinstall Snazzy theme."
fi

if /usr/libexec/PlistBuddy -c "Print 'Window Settings':$THEME_NAME" "$PLIST" &>/dev/null && [[ "$FORCE" == false ]]; then
    echo "✅ Terminal profile '$THEME_NAME' already exists. Skipping installation."
    exit 0
fi

# Download Snazzy theme for Terminal.app
THEME_URL="https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/terminal/Snazzy.terminal"
THEME_NAME="Snazzy"

TMP_DIR=$(mktemp -d)
THEME_PATH="$TMP_DIR/Snazzy.terminal"

echo "🎨 Downloading Snazzy theme for Terminal.app..."
curl -fsSL -o "$THEME_PATH" "$THEME_URL"

echo "📂 Importing the theme into Terminal.app..."
open "$THEME_PATH"
echo "🧼 You may close the extra Terminal window that opened when importing the theme."

# Give Terminal time to register the theme
sleep 2

echo "📌 Setting Snazzy as the default Terminal profile..."
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

# Cleanup
rm -rf "$TMP_DIR"

echo "🎉 Done! Terminal.app is now using the Snazzy theme with Menlo 12pt font."