#!/bin/bash

# CloudUploaderCLI Uninstallation Script

set -e  # Exit on error

# Colors for output (disable on Windows)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    RED=""
    GREEN=""
    YELLOW=""
    NC=""
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
fi

# Detect OS
detect_os() {
    case "$OSTYPE" in
        msys*|cygwin*)    echo "windows" ;;
        darwin*)          echo "macos" ;;
        linux*)           echo "linux" ;;
        *)               echo "unknown" ;;
    esac
}

# Get installation directory based on OS
get_install_dir() {
    local os=$(detect_os)
    case "$os" in
        windows)
            echo "$USERPROFILE/clouduploader-cli"
            ;;
        macos|linux)
            echo "/usr/local/bin/clouduploader-cli"
            ;;
        *)
            echo "$HOME/clouduploader-cli"
            ;;
    esac
}

# Get config directory based on OS
get_config_dir() {
    local os=$(detect_os)
    case "$os" in
        windows)
            echo "$APPDATA/clouduploader-cli"
            ;;
        macos)
            echo "$HOME/Library/Application Support/clouduploader-cli"
            ;;
        linux)
            echo "$HOME/.config/clouduploader-cli"
            ;;
        *)
            echo "$HOME/.clouduploader-cli"
            ;;
    esac
}

# Remove installation
remove_installation() {
    echo "Removing CloudUploaderCLI..."
    
    local install_dir=$(get_install_dir)
    local config_dir=$(get_config_dir)
    local os=$(detect_os)
    
    case "$os" in
        windows)
            # Remove from Windows PATH
            setx PATH "%PATH:;$install_dir=%"
            # Remove files
            rm -rf "$install_dir"
            # Ask about config removal
            read -p "Remove configuration files? (y/n): " remove_config
            if [[ "$remove_config" == "y" ]]; then
                rm -rf "$config_dir"
            fi
            ;;
        *)
            # Remove symlink
            sudo rm -f "/usr/local/bin/clouduploader"
            # Remove installation directory
            sudo rm -rf "$install_dir"
            # Ask about config removal
            read -p "Remove configuration files? (y/n): " remove_config
            if [[ "$remove_config" == "y" ]]; then
                rm -rf "$config_dir"
            fi
            ;;
    esac
}

# Clean up shell configuration
cleanup_shell_config() {
    local os=$(detect_os)
    if [[ "$os" != "windows" ]]; then
        # Remove PATH additions
        for rc in ~/.bashrc ~/.zshrc; do
            if [[ -f "$rc" ]]; then
                sed -i.bak '/clouduploader-cli/d' "$rc"
                rm -f "${rc}.bak"
            fi
        done
    fi
}

# Verify uninstallation
verify_uninstallation() {
    echo "Verifying uninstallation..."
    
    local install_dir=$(get_install_dir)
    local os=$(detect_os)
    
    if [[ "$os" == "windows" ]]; then
        if [[ ! -d "$install_dir" ]]; then
            echo -e "${GREEN}CloudUploaderCLI uninstalled successfully!${NC}"
        else
            echo -e "${RED}Uninstallation failed${NC}"
            exit 1
        fi
    else
        if ! command -v clouduploader &> /dev/null; then
            echo -e "${GREEN}CloudUploaderCLI uninstalled successfully!${NC}"
        else
            echo -e "${RED}Uninstallation failed${NC}"
            exit 1
        fi
    fi
}

# Main uninstallation process
main() {
    echo "Starting uninstallation..."
    
    # Confirm uninstallation
    read -p "Are you sure you want to uninstall CloudUploaderCLI? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
    
    remove_installation
    cleanup_shell_config
    verify_uninstallation
    
    echo -e "\n${GREEN}Uninstallation complete!${NC}"
    if [[ $(detect_os) != "windows" ]]; then
        echo "Please run 'source ~/.bashrc' or 'source ~/.zshrc' to update your shell"
    fi
}

# Run uninstallation
main 