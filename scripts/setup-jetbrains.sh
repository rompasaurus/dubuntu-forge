#!/bin/bash
# Install JetBrains Toolbox App for managing all JetBrains IDEs

set -e

echo "=== Installing JetBrains Toolbox ==="

# Dependencies
sudo apt update
sudo apt install -y curl libfuse2t64

# Download latest Toolbox
echo "Downloading JetBrains Toolbox..."
curl -fsSL -o /tmp/jetbrains-toolbox.tar.gz \
    "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"

# Extract and install
echo "Extracting..."
tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /tmp

# Move to /opt
TOOLBOX_DIR=$(find /tmp -maxdepth 1 -name "jetbrains-toolbox-*" -type d | head -1)
sudo mv "$TOOLBOX_DIR/jetbrains-toolbox" /opt/jetbrains-toolbox

# Cleanup
rm -rf /tmp/jetbrains-toolbox*

# Create desktop launcher
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/jetbrains-toolbox.desktop << EOF
[Desktop Entry]
Name=JetBrains Toolbox
Comment=Manage JetBrains IDEs
Exec=/opt/jetbrains-toolbox
Icon=jetbrains-toolbox
Terminal=false
Type=Application
Categories=Development;IDE;
Keywords=jetbrains;intellij;pycharm;webstorm;clion;goland;rider;
StartupNotify=true
EOF

update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

# Launch Toolbox
echo ""
echo "=== Launching JetBrains Toolbox ==="
/opt/jetbrains-toolbox &

echo ""
echo "=== Done! ==="
echo ""
echo "JetBrains Toolbox is running. From it you can install:"
echo "  - IntelliJ IDEA Ultimate  (Java, Kotlin, Spring)"
echo "  - WebStorm                (JavaScript, TypeScript)"
echo "  - PyCharm                 (Python)"
echo "  - CLion                   (C/C++, Rust)"
echo "  - GoLand                  (Go)"
echo "  - Rider                   (.NET, C#, Unity)"
echo "  - PhpStorm                (PHP)"
echo "  - RubyMine                (Ruby)"
echo "  - DataGrip                (SQL, Databases)"
echo "  - RustRover               (Rust)"
echo "  - Aqua                    (Test Automation)"
echo ""
echo "Toolbox auto-starts on login and keeps all IDEs updated."
echo "You'll need a JetBrains license to use the IDEs."
