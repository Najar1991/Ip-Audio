#!/bin/bash

# MixAudio Installer - Clean upgrade path with dependencies
version="1.0"
ipkurl="https://github.com/Najar1991/Ip-Audio/raw/main/MixAudio.ipk"

echo ""
echo "MixAudio Installer v$version"
echo "============================"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root!"
    exit 1
fi

# CHECK & REMOVE PREVIOUS MixAudio ONLY
# (We explicitly DO NOT touch the original IPAudio)
echo "=== Checking for previous MixAudio ==="
if opkg list-installed | grep -q "enigma2-plugin-extensions-mixaudio"; then
    echo "Previous MixAudio found - removing..."
    opkg remove enigma2-plugin-extensions-mixaudio --force-depends
    rm -rf /usr/lib/enigma2/python/Plugins/Extensions/MixAudio
    echo "✓ MixAudio removed (Ready for upgrade)"
else
    echo "No previous MixAudio - fresh install"
fi

# Backup playlists ONLY if exist (Specified for MixAudio paths)
echo "=== Backing up MixAudio playlists ==="
if [ -d "/etc/enigma2/mixaudio" ]; then
    backup_dir="/tmp/mixaudiobackup-$(date +%Y%m%d-%H%M%S)"
    cp -r /etc/enigma2/mixaudio "$backup_dir/" 2>/dev/null
    # Also backup the json file if it exists in the root of etc/enigma2
    if [ -f "/etc/enigma2/mixaudio.json" ]; then
        cp /etc/enigma2/mixaudio.json "$backup_dir/"
    fi
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

# Core dependencies (Same as IPAudio)
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
tmp_dir="/tmp/mixaudio-install"
mkdir -p "$tmp_dir"
cd "$tmp_dir" || exit 1

echo "=== Downloading MixAudio v$version ==="
# Note: Ensure ipkurl is valid
wget --no-check-certificate -q --show-progress "$ipkurl" -O MixAudio.ipk

if [ ! -f MixAudio.ipk ] || [ ! -s MixAudio.ipk ]; then
    echo "❌ Download failed! Please check the URL in the script."; 
    rm -rf "$tmp_dir"; 
    exit 1
fi

echo "✓ Download completed"
echo ""

echo "=== Installing ==="
opkg install --force-overwrite ./MixAudio.ipk

if [ $? -eq 0 ]; then
    # Rebuild GStreamer cache
    echo "=== Rebuilding GStreamer cache ==="
    rm -rf /root/.cache/gstreamer-1.0/ 2>/dev/null
    rm -rf /home/root/.cache/gstreamer-1.0/ 2>/dev/null
    if command -v gst-inspect-1.0 >/dev/null 2>&1; then
        gst-inspect-1.0 > /dev/null 2>&1
        echo "✓ GStreamer cache rebuilt"
    fi
    
    # Restore Playlist if backup existed
    if [ -n "$backup_dir" ]; then
         echo "=== Restoring Configuration ==="
         cp -r "$backup_dir"/* /etc/enigma2/mixaudio/ 2>/dev/null
         if [ -f "$backup_dir/mixaudio.json" ]; then
            cp "$backup_dir/mixaudio.json" /etc/enigma2/
         fi
         echo "✓ Configuration restored"
    fi

    echo ""
    echo "🎉 MixAudio v$version INSTALLED SUCCESSFULLY!"
    echo "====================================="
    echo "- Plugin: /usr/lib/enigma2/python/Plugins/Extensions/MixAudio/"
    echo "- Config: /etc/enigma2/mixaudio.json"
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
