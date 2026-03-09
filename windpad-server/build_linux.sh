#!/bin/bash
echo "Building Windpad Helper for Linux..."

# Build with PyInstaller
pyinstaller --onefile --name="windpad-helper" main.py

# Create windpad.desktop
cat << 'EOF' > windpad.desktop
[Desktop Entry]
Name=Windpad Helper
Exec=/usr/local/bin/windpad-helper
Icon=windpad
Type=Application
Categories=Utility;
StartupNotify=false
X-GNOME-Autostart-enabled=true
EOF

echo "Creating .deb package with fpm..."
if command -v fpm &> /dev/null; then
    fpm -s dir -t deb \
      -n windpad-helper \
      -v 1.0.0 \
      --description "Windpad Companion App" \
      --maintainer "Aditya" \
      dist/windpad-helper=/usr/local/bin/windpad-helper \
      windpad.png=/usr/share/pixmaps/windpad.png \
      windpad.desktop=/usr/share/applications/windpad.desktop
    echo "DEB package created."
else
    echo "fpm not found, skipping DEB packaging."
fi

echo "Creating AppImage..."
if command -v linuxdeploy &> /dev/null; then
    linuxdeploy --appdir AppDir \
      --executable dist/windpad-helper \
      --desktop-file windpad.desktop \
      --icon-file windpad.png \
      --output appimage
    echo "AppImage created."
else
    echo "linuxdeploy not found, skipping AppImage."
fi
