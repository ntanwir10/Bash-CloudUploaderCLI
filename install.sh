#!/bin/bash

# CloudUploaderCLI Installation Script

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

# Check for required commands
check_requirements() {
    echo "Checking requirements..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error: AWS CLI is not installed${NC}"
        local os=$(detect_os)
        case "$os" in
            windows)
                echo "Download AWS CLI installer from: https://aws.amazon.com/cli/"
                ;;
            macos)
                echo "Install with: brew install awscli"
                ;;
            linux)
                echo "Install with: sudo apt-get install awscli (Debian/Ubuntu)"
                echo "or: sudo yum install awscli (RHEL/CentOS)"
                ;;
        esac
        exit 1
    fi
}

# Create directories
setup_directories() {
    echo "Setting up directories..."
    
    local install_dir=$(get_install_dir)
    local config_dir=$(get_config_dir)
    
    # Create directories based on OS
    if [[ $(detect_os) == "windows" ]]; then
        mkdir -p "$install_dir"
        mkdir -p "$config_dir"
    else
        sudo mkdir -p "$install_dir"
        mkdir -p "$config_dir"
    fi
}

# Copy files
copy_files() {
    echo "Copying files..."
    
    local install_dir=$(get_install_dir)
    local config_dir=$(get_config_dir)
    local os=$(detect_os)
    
    # Copy files based on OS
    if [[ "$os" == "windows" ]]; then
        # Copy utility files
        cp src/aws_utils.sh "$install_dir/"
        cp src/validation.sh "$install_dir/"
        cp src/clouduploader.sh "$install_dir/"
        
        # Create batch wrapper
        echo "@echo off" > "$install_dir/clouduploader.bat"
        echo "bash \"%~dp0/clouduploader.sh\" %*" >> "$install_dir/clouduploader.bat"
    else
        # Copy utility files
        sudo cp src/aws_utils.sh "$install_dir/"
        sudo cp src/validation.sh "$install_dir/"
        sudo cp src/clouduploader.sh "$install_dir/"
    fi

    # Create .env template
    cat > "$config_dir/.env.template" << EOL
# AWS Credentials - Required for AWS CLI authentication
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_DEFAULT_REGION=us-east-1

# S3 Configuration
AWS_BUCKET_NAME=your_bucket_name
AWS_STORAGE_CLASS=STANDARD

# Application Settings
CLOUDUPLOADER_DEBUG=false
CLOUDUPLOADER_LOG_LEVEL=INFO
CLOUDUPLOADER_MAX_FILE_SIZE=5GB

# Security Settings
ENABLE_ENCRYPTION=true
KMS_KEY_ID=your_kms_key_id

# Feature Flags
ENABLE_PROGRESS_BAR=true
ENABLE_MULTIPART_UPLOAD=true
ENABLE_VERSIONING=false
EOL

    # Create .env if it doesn't exist
    if [[ ! -f "$config_dir/.env" ]]; then
        cp "$config_dir/.env.template" "$config_dir/.env"
        echo -e "${YELLOW}Please edit $config_dir/.env with your AWS credentials${NC}"
    fi
}

# Set up command access
setup_command() {
    echo "Setting up command access..."
    
    local install_dir=$(get_install_dir)
    local os=$(detect_os)
    
    case "$os" in
        windows)
            # Add to PATH in Windows registry
            setx PATH "%PATH%;$install_dir"
            ;;
        *)
            # Create symlink for Unix-like systems
            sudo ln -sf "$install_dir/clouduploader.sh" "/usr/local/bin/clouduploader"
            sudo chmod +x "/usr/local/bin/clouduploader"
            sudo chmod +x "$install_dir"/*.sh
            ;;
    esac
}

# Configure environment
configure_env() {
    echo "Configuring environment..."
    
    local config_dir=$(get_config_dir)
    local os=$(detect_os)
    
    # Add to PATH if needed
    if [[ "$os" != "windows" ]]; then
        if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
            for rc in ~/.bashrc ~/.zshrc; do
                if [[ -f "$rc" ]]; then
                    echo 'export PATH="/usr/local/bin:$PATH"' >> "$rc"
                fi
            done
        fi
    fi
}

# Verify installation
verify_installation() {
    echo "Verifying installation..."
    
    local install_dir=$(get_install_dir)
    local os=$(detect_os)
    
    if [[ "$os" == "windows" ]]; then
        if [[ -f "$install_dir/clouduploader.bat" ]]; then
            echo -e "${GREEN}CloudUploaderCLI installed successfully!${NC}"
            echo "Run 'clouduploader --help' to get started"
        else
            echo -e "${RED}Installation failed${NC}"
            exit 1
        fi
    else
        if command -v clouduploader &> /dev/null; then
            echo -e "${GREEN}CloudUploaderCLI installed successfully!${NC}"
            echo "Run 'clouduploader --help' to get started"
        else
            echo -e "${RED}Installation failed${NC}"
            exit 1
        fi
    fi
}

# Main installation process
main() {
    echo "Installing CloudUploaderCLI..."
    
    check_requirements
    setup_directories
    copy_files
    setup_command
    configure_env
    verify_installation
    
    echo -e "\n${GREEN}Installation complete!${NC}"
    echo "Please:"
    echo "1. Edit $(get_config_dir)/.env with your AWS credentials"
    if [[ $(detect_os) != "windows" ]]; then
        echo "2. Run 'source ~/.bashrc' or 'source ~/.zshrc' to update your shell"
    fi
    echo "3. Try 'clouduploader --help' to get started"
}

# Run installation
main
