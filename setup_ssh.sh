#!/bin/bash
set -e

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID,,}"  # normalize to lowercase
else
    echo "[x] Cannot detect OS. /etc/os-release not found."
    exit 1
fi

# Allow only Ubuntu or Debian
if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
    echo "[x] Unsupported OS: $OS_ID. This script supports only Ubuntu or Debian."
    exit 1
fi

echo "[✓] Detected supported OS: $PRETTY_NAME"

echo "[+] Updating system..."
sudo apt update

echo "[+] Installing OpenSSH Server..."
sudo apt install -y openssh-server

echo "[+] Enabling and starting ssh service..."
sudo systemctl enable ssh
sudo systemctl start ssh

echo "[+] Checking firewall (ufw)..."
if command -v ufw >/dev/null; then
    if sudo ufw status | grep -q "Status: active"; then
        echo "[+] UFW is active. Allowing SSH..."
        sudo ufw allow ssh
        sudo ufw reload
    else
        echo "[!] UFW is not active. Skipping firewall configuration."
    fi
else
    echo "[!] UFW is not installed. Skipping firewall configuration."
fi

# Optional hardening
HARDEN=${1:-false}
if [ "$HARDEN" = "true" ]; then
    echo "[+] Hardening SSH configuration..."
    sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl reload ssh
    echo "[✓] SSH hardened: root login disabled, password auth disabled."
fi

# Optional SSH key setup
if [ -n "$2" ]; then
    PUBKEY_PATH="$2"
    echo "[+] Setting up SSH key authentication..."
    if [ ! -f "$PUBKEY_PATH" ]; then
        echo "[x] Public key file not found: $PUBKEY_PATH"
        exit 1
    fi

    USER_HOME=$(eval echo "~$USER")
    mkdir -p "$USER_HOME/.ssh"
    cat "$PUBKEY_PATH" >> "$USER_HOME/.ssh/authorized_keys"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    chown -R "$USER":"$USER" "$USER_HOME/.ssh"
    echo "[✓] SSH key added for user $USER"
fi

echo "[✓] SSH setup complete."
echo "Your IP address is: $(hostname -I | awk '{print $1}')"
