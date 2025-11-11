#!/bin/bash
# Setup script to copy doctl config from host to container
# Handles both macOS and Linux host configurations

set -e

# Fix ownership of .config if it was created by root (happens with gh mount)
if [ -d "/home/devcontainer/.config" ]; then
    # Check if owned by root and fix it
    if [ "$(stat -c %U /home/devcontainer/.config)" = "root" ]; then
        echo "Fixing ownership of .config directory..."
        sudo chown -R devcontainer:devcontainer /home/devcontainer/.config
    fi
fi

# Create .config directory first if it doesn't exist
mkdir -p "/home/devcontainer/.config"

DOCTL_CONFIG_DIR="/home/devcontainer/.config/doctl"
mkdir -p "$DOCTL_CONFIG_DIR"

# Function to check and copy config
copy_config() {
    local source_dir=$1
    local location_name=$2
    
    if [ -d "$source_dir" ]; then
        # Check if directory has content (not just empty mount point)
        if [ -f "$source_dir/config.yaml" ] || [ "$(ls -A "$source_dir" 2>/dev/null | grep -v '^\.')" ]; then
            echo "Found doctl config in $location_name location, copying..."
            cp -r "$source_dir"/* "$DOCTL_CONFIG_DIR/" 2>/dev/null || true
            echo "✓ doctl config copied from $location_name location"
            return 0
        fi
    fi
    return 1
}

# Try macOS location first (if mounted and has content)
if copy_config "/tmp/doctl-config-mac" "macOS"; then
    : # Success, config copied
# Try Linux location (if mounted and has content)
elif copy_config "/tmp/doctl-config-linux" "Linux"; then
    : # Success, config copied
else
    echo "⚠ Warning: doctl config not found in mounted locations"
    echo "  This is normal if:"
    echo "    - You're on Linux and need to update devcontainer.json mount path"
    echo "    - You haven't run 'doctl auth init' on your host yet"
    echo ""
    echo "  Expected locations:"
    echo "    macOS: ~/Library/Application Support/doctl/config.yaml"
    echo "    Linux: ~/.config/doctl/config.yaml"
fi

# Verify doctl config exists
if [ -f "$DOCTL_CONFIG_DIR/config.yaml" ]; then
    echo "✓ doctl config is ready at $DOCTL_CONFIG_DIR/config.yaml"
    # Test doctl if available
    if command -v doctl >/dev/null 2>&1; then
        echo "  Testing doctl authentication..."
        doctl auth list >/dev/null 2>&1 && echo "  ✓ doctl authentication verified" || echo "  ⚠ doctl auth check failed (may need to re-authenticate)"
    fi
else
    echo "⚠ doctl config.yaml not found. You may need to:"
    echo "  1. Run 'doctl auth init' on your host machine, or"
    echo "  2. Run 'doctl auth init' inside the container"
fi

