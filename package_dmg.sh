#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=========================================="
echo "⚡ RESTATS (RESET + STATS) - GERADOR DMG"
echo "=========================================="

echo "🔨 1. Compilando binário nativo Apple Silicon (Release)..."
cd "$DIR/mac"
swift build -c release
cd "$DIR"

BIN_PATH="$DIR/mac/.build/release/ReStats"
APP_PATH="$DIR/ReStats.app"
DMG_NAME="ReStats-AppleSilicon.dmg"
DMG_PATH="$DIR/$DMG_NAME"
STAGING_DIR="$DIR/.dmg_staging"

echo "📦 2. Montando estrutura do ReStats.app..."
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

echo "🔏 3. Assinando ReStats.app (Ad-hoc codesign)..."
codesign --force --deep -s - "$APP_PATH"
xattr -cr "$APP_PATH" 2>/dev/null || true

echo "💿 4. Preparando imagem DMG com atalho para /Applications..."
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "🚀 5. Gerando $DMG_NAME compactado (UDZO)..."
hdiutil create -volname "ReStats" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_PATH"
rm -rf "$STAGING_DIR"

echo "🧪 6. Testando integridade do DMG..."
hdiutil imageinfo "$DMG_PATH" > /dev/null

MOUNT_INFO=$(hdiutil attach "$DMG_PATH" -nobrowse -readonly 2>/dev/null || true)
MOUNT_DIR=$(echo "$MOUNT_INFO" | grep "/Volumes" | awk -F'\t' '{print $NF}' | xargs)
if [ -n "$MOUNT_DIR" ] && [ -d "$MOUNT_DIR" ]; then
    echo "   Volume montado com sucesso em: $MOUNT_DIR"
    ls -la "$MOUNT_DIR"
    hdiutil detach "$MOUNT_DIR" 2>/dev/null || true
    echo "   Volume desmontado com sucesso."
fi

DMG_SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')
SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')

echo "=========================================="
echo "✅ SUCESSO TOTAL!"
echo "📍 DMG Gerado: $DMG_PATH"
echo "📏 Tamanho: $DMG_SIZE"
echo "🔒 SHA256: $SHA256"
echo "=========================================="
