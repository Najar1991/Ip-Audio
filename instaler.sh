#!/bin/bash

# IPAudio Installer - Clean upgrade path with dependencies
version="1.0"
ipkurl="https://github.com/Najar1991/Ip-Audio/raw/main/Ipaudio.ipk"

echo ""
echo "IPAudio Installer v$version"
echo "============================"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root!"
    exit 1
fi

# CHECK & REMOVE PREVIOUS IPAudio ONLY
echo "=== Checking for previous IPAudio ==="
if opkg list-installed | grep -q "enigma2-plugin-extensions-ipaudio"; then
    echo "Previous IPAudio found - removing..."
    opkg remove enigma2-plugin-extensions-ipaudio --force-depends
    rm -rf /usr/lib/enigma2/python/Plugins/Extensions/IPAudio
    echo "✓ IPAudio removed"
else
    echo "No previous IPAudio - fresh install"
fi

# Backup playlists ONLY if exist
echo "=== Backing up playlists ==="
if [ -d "/etc/enigma2/ipaudio" ] && [ "$(ls -A /etc/enigma2/ipaudio/*.json 2>/dev/null | wc -l)" -gt 0 ]; then
    backup_dir="/tmp/ipaudiobackup-$(date +%Y%m%d-%H%M%S)"
    cp -r /etc/enigma2/ipaudio "$backup_dir/"
    echo "✓ Playlists backed up: $backup_dir"
fi

# === CHECK & INSTALL DEPENDENCIES ===
echo "=== Checking Dependencies ==="

# Update package list
echo "Updating package list..."
opkg update > /dev/null 2>&1

# Function to install if missing
install_if_missing() {
    PKG=$1
    if ! opkg list-installed | grep -q "^$PKG "; then
        echo "  → Installing $PKG..."
        opkg install "$PKG" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "    ✓ $PKG installed"
        else
            echo "    ⚠ Warning: Failed to install $PKG (may not be critical)"
        fi
    else
        echo "  ✓ $PKG already installed"
    fi
}

# Core dependencies
install_if_missing "ffmpeg"
install_if_missing "gstreamer1.0"
install_if_missing "gstreamer1.0-plugins-base"
install_if_missing "gstreamer1.0-plugins-good"
install_if_missing "gstreamer1.0-plugins-bad"
install_if_missing "gstreamer1.0-plugins-ugly"
install_if_missing "gstreamer1.0-libav"
install_if_missing "python3-core"
install_if_missing "python3-twisted"

# Optional but recommended
install_if_missing "alsa-utils"

echo "✓ Dependencies checked"
echo ""

# Download & Install
tmp_dir="/tmp/ipaudio-install"
mkdir -p "$tmp_dir"
cd "$tmp_dir" || exit 1

echo "=== Downloading IPAudio v$version ==="
wget --no-check-certificate -q --show-progress "$ipkurl" -O Ipaudio.ipk

if [ ! -f Ipaudio.ipk ] || [ ! -s Ipaudio.ipk ]; then
    echo "❌ Download failed!"; 
    rm -rf "$tmp_dir"; 
    exit 1
fi

echo "✓ Download completed ($(du -h Ipaudio.ipk | cut -f1))"
echo ""

echo "=== Installing ==="
opkg install --force-overwrite ./Ipaudio.ipk

if [ $? -eq 0 ]; then
    # Rebuild GStreamer cache
    echo "=== Rebuilding GStreamer cache ==="
    rm -rf /root/.cache/gstreamer-1.0/ 2>/dev/null
    rm -rf /home/root/.cache/gstreamer-1.0/ 2>/dev/null
    if command -v gst-inspect-1.0 >/dev/null 2>&1; then
        gst-inspect-1.0 > /dev/null 2>&1
        echo "✓ GStreamer cache rebuilt"
    fi
    
    echo ""
    echo "🎉 IPAudio v$version INSTALLED SUCCESSFULLY!"
    echo "====================================="
    echo "- Plugin: /usr/lib/enigma2/python/Plugins/Extensions/IPAudio/"
    echo "- Playlists: /etc/enigma2/ipaudio/"
    if [ -n "$backup_dir" ]; then
        echo "- Backup: $backup_dir"
    fi
    echo ""
    echo "🔄 RESTARTING ENIGMA2 in 3s..."
    sleep 3
    killall -9 enigma2
else
    echo "❌ Installation FAILED!"
    echo "Check /var/log/opkg.log for details"
    rm -rf "$tmp_dir"
    exit 1
fi

rm -rf "$tmp_dir"
exit 0    echo "- Plugin: /usr/lib/enigma2/python/Plugins/Extensions/IPAudio/"
    echo "- Playlists: /etc/enigma2/ipaudio/"
    if [ -n "$backup_dir" ]; then
        echo "- Backup: $backup_dir"
    fi
    echo ""
    echo "🔄 RESTARTING ENIGMA2 in 3s..."
    sleep 3
    killall -9 enigma2
else
    echo "❌ Installation FAILED!"
    echo "Check /var/log/opkg.log for details"
    rm -rf "$tmp_dir"
    exit 1
fi

rm -rf "$tmp_dir"
exit 0
