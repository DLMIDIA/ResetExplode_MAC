#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR/mac"

echo "🔨 Compilando ReStats para Apple Silicon (Release)..."
swift build -c release

BIN_PATH="$DIR/mac/.build/release/ReStats"
APP_PATH="$DIR/ReStats.app"

echo "📦 Empacotando ReStats.app..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp "$BIN_PATH" "$APP_PATH/Contents/MacOS/ReStats"

if [ -f "$DIR/Assets/AppIcon.icns" ]; then
    cp "$DIR/Assets/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
fi

cat <<EOF > "$APP_PATH/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>ReStats</string>
    <key>CFBundleDisplayName</key>
    <string>ReStats</string>
    <key>CFBundleIdentifier</key>
    <string>br.com.dlmidia.restats</string>
    <key>CFBundleVersion</key>
    <string>1.2.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.2.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>ReStats</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>O ReStats analisa dispositivos e periféricos Bluetooth para monitorar status e diagnóstico de hardware.</string>
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>O ReStats analisa dispositivos e periféricos Bluetooth para monitorar status e diagnóstico de hardware.</string>
</dict>
</plist>
EOF

chmod +x "$APP_PATH/Contents/MacOS/ReStats"
codesign --force --deep -s - "$APP_PATH"
xattr -cr "$APP_PATH" 2>/dev/null || true

echo "✅ Sucesso! Aplicativo gerado em: $APP_PATH"
