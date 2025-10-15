#!/bin/bash

GITHUB_REPO="mspiq/webminer"

echo "🔧 Installing webminer..."

# Download tool from GitHub
if curl -s -L "https://github.com/$GITHUB_REPO/raw/main/webminer.sh" -o "/tmp/webminer.sh"; then
    sudo cp "/tmp/webminer.sh" /usr/local/bin/webminer
    sudo chmod +x /usr/local/bin/webminer
    
    # Create config directory
    sudo mkdir -p /usr/local/etc/
    
    echo "✅ Installation successful!"
    echo "💡 Usage:"
    echo "   webminer -u example.com"
    echo "   webminer --check-update"
else
    echo "❌ Installation failed"
    exit 1
fi
