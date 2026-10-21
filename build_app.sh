#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR/mac"

echo "🔨 Compilando ResetExplode para Apple Silicon (Release)..."
swift build -c release

BIN_PATH="$DIR/mac/.build/release/ResetExplode"
APP_PATH="$DIR/ResetExplode.app"

echo "📦 Empacotando ResetExplode.app..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

cp "$BIN_PATH" "$APP_PATH/Contents/MacOS/ResetExplode"

if [ -f "$DIR/Assets/AppIcon.icns" ]; then
    cp "$DIR/Assets/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"
fi

cat <<EOF > "$APP_PATH/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>ResetExplode</string>
    <key>CFBundleDisplayName</key>
    <string>ResetExplode</string>
    <key>CFBundleIdentifier</key>
    <string>br.com.dlmidia.resetexplode</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>ResetExplode</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

chmod +x "$APP_PATH/Contents/MacOS/ResetExplode"
xattr -cr "$APP_PATH" 2>/dev/null || true

echo "✅ Sucesso! Aplicativo gerado em: $APP_PATH"
