#!/bin/sh

# ==========================================================
#  IPAudio Smart Installer
# ==========================================================

# 1. Configuration
# Ensure the IPK filename matches exactly what is in your repo
IPK_URL="https://github.com/Najar1991/Ip-Audio/raw/main/enigma2-plugin-extensions-ipaudio_1.0-r20260125-1241_all.ipk"
PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/IPAudio"
TMP_IPK="/tmp/ipaudio_installer.ipk"

echo ""
echo "#########################################################"
echo "#      IPAudio SMART INSTALLER - FORCE CLEAN MODE       #"
echo "#########################################################"
echo ""

# 2. Force Clean (Remove old files to prevent crashes)
if [ -d "$PLUGIN_DIR" ]; then
    echo "> Found old version. Removing..."
    rm -rf "$PLUGIN_DIR"
    echo "> Old folder deleted."
else
    echo "> No old folder found (Clean Install)."
fi

# Remove from opkg database to avoid conflicts
opkg remove --force-depends enigma2-plugin-extensions-ipaudio > /dev/null 2>&1

echo ""

# 3. Install Dependencies (FFmpeg & GStreamer)
echo "> Checking and Installing Dependencies..."
opkg update > /dev/null 2>&1
opkg install ffmpeg gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav python3-core > /dev/null 2>&1
echo "> Dependencies checked."

echo ""

# 4. Download and Install IPK
echo "> Downloading new version..."
wget --no-check-certificate "$IPK_URL" -O $TMP_IPK

if [ -f $TMP_IPK ]; then
    echo "> Installing IPK..."
    opkg install --force-overwrite $TMP_IPK
    
    # Check if installation was successful
    if [ $? -eq 0 ]; then
        echo ""
        echo "#########################################################"
        echo "#           INSTALLATION SUCCESSFUL                     #"
        echo "#           RESTARTING ENIGMA2...                       #"
        echo "#########################################################"
        rm -f $TMP_IPK
        sleep 3
        killall -9 enigma2
    else
        echo ">>>> ERROR: Installation failed! Try manual install."
    fi
else
    echo ">>>> ERROR: Download Failed! Check URL or Internet connection."
fi