#!/bin/bash
echo "Building Windpad Helper for macOS..."

# Build with PyInstaller
pyinstaller --onefile --noconsole --icon=windpad.icns --name="WindpadHelper" main.py

# Create .app bundle structure
mkdir -p dist/WindpadHelper.app/Contents/MacOS
mkdir -p dist/WindpadHelper.app/Contents/Resources

cp dist/WindpadHelper dist/WindpadHelper.app/Contents/MacOS/
cp windpad.icns dist/WindpadHelper.app/Contents/Resources/

# Create Info.plist
cat << 'EOF' > dist/WindpadHelper.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Windpad Helper</string>
    <key>CFBundleExecutable</key>
    <string>WindpadHelper</string>
    <key>CFBundleIconFile</key>
    <string>windpad</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleIdentifier</key>
    <string>com.windpad.helper</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

if command -v create-dmg &> /dev/null; then
    echo "Creating DMG package..."
    create-dmg \
      --volname "Windpad Helper" \
      --window-size 400 300 \
      --icon-size 100 \
      --app-drop-link 300 150 \
      "WindpadHelper.dmg" \
      "dist/WindpadHelper.app"
else
    echo "create-dmg not found. Skipping DMG build. The Mac App is located in dist/WindpadHelper.app"
fi
