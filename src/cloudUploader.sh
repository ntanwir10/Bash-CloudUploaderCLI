#!/bin/bash

# CloudUploaderCLI - A tool for uploading files to AWS S3
# Author: Noman Tanwir
# Version: 1.0.0

set -e  # Exit on error
set -u  # Exit on undefined variable

# Source utility functions
SCRIPT_DIR="/usr/local/bin/clouduploader-cli"
if [[ ! -d "$SCRIPT_DIR" ]]; then
    # Fallback to the development directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Source required files
for util in aws_utils.sh validation.sh; do
    util_path="$SCRIPT_DIR/$util"
    if [[ ! -f "$util_path" ]]; then
        echo "Error: Required utility file not found: $util"
        echo "Expected location: $util_path"
        exit 1
    fi
    source "$util_path"
done

# Constants
PROGRAM_NAME="clouduploader"
VERSION="1.0.0"
VALID_STORAGE_CLASSES="STANDARD REDUCED_REDUNDANCY STANDARD_IA ONEZONE_IA INTELLIGENT_TIERING GLACIER DEEP_ARCHIVE"

# Colors
NEON_GREEN='\033[38;5;82m'
RESET='\033[0m'

# Show ASCII banner
show_banner() {
    echo -e "${NEON_GREEN}"
    cat << "EOF"
 ______     __         ______     __  __     _____     
/\  ___\   /\ \       /\  __ \   /\ \/\ \   /\  __-.  
\ \ \____  \ \ \____  \ \ \/\ \  \ \ \_\ \  \ \ \/\ \ 
 \ \_____\  \ \_____\  \ \_____\  \ \_____\  \ \____- 
  \/_____/   \/_____/   \/_____/   \/_____/   \/____/ 
    __  __     ______   __         ______     ______     _____     ______     ______    
   /\ \/\ \   /\  == \ /\ \       /\  __ \   /\  __ \   /\  __-.  /\  ___\   /\  == \   
   \ \ \_\ \  \ \  _-/ \ \ \____  \ \ \/\ \  \ \  __ \  \ \ \/\ \ \ \  __\   \ \  __<   
    \ \_____\  \ \_\    \ \_____\  \ \_____\  \ \_\ \_\  \ \____-  \ \_____\  \ \_\ \_\ 
     \/_____/   \/_/     \/_____/   \/_____/   \/_/\/_/   \/____/   \/_____/   \/_/ /_/ 
EOF
    echo -e "Version: $VERSION"
    echo -e "----------------------------------------${RESET}"
}

# Configure pv with neon green color
configure_pv() {
    # Set PV_COLORS environment variable for neon green progress bar
    export PV_COLORS="0;32"  # Bright green
    # Additional PV options for better visibility
    export PV_OPTS="-pterb"  # progress, timer, rate, bytes
}

# Detect package manager and install command
get_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt-get install -y"
    elif command -v yum &> /dev/null; then
        echo "yum install -y"
    elif command -v brew &> /dev/null; then
        echo "brew install"
    else
        echo ""
    fi
}

# Check and install pv if needed
check_pv() {
    if ! command -v pv &> /dev/null && [[ "${SHOW_PROGRESS:-true}" == "true" ]]; then
        local os=$(detect_os)
        case "$os" in
            windows)
                echo "Warning: Progress bar not supported on Windows"
                export SHOW_PROGRESS=false
                return
                ;;
            *)
                local install_cmd=$(get_package_manager)
                if [[ -z "$install_cmd" ]]; then
                    echo "Warning: Package manager not found. Please install 'pv' manually."
                    echo "Progress bar will be disabled."
                    export SHOW_PROGRESS=false
                    return
                fi

                echo -e "${NEON_GREEN}The 'pv' package is required for progress bar functionality.${RESET}"
                read -p "Would you like to install it now? (y/n): " choice
                case "$choice" in
                    y|Y)
                        echo "Installing pv..."
                        if [[ "$install_cmd" == *"apt-get"* || "$install_cmd" == *"yum"* ]]; then
                            sudo $install_cmd pv
                        else
                            $install_cmd pv
                        fi
                        if ! command -v pv &> /dev/null; then
                            echo "Failed to install pv. Progress bar will be disabled."
                            export SHOW_PROGRESS=false
                        else
                            echo -e "${NEON_GREEN}Successfully installed pv.${RESET}"
                            configure_pv
                        fi
                        ;;
                    *)
                        echo "Progress bar will be disabled."
                        export SHOW_PROGRESS=false
                        ;;
                esac
                ;;
        esac
    else
        configure_pv
    fi
}

# Help message
show_help() {
    show_banner
    cat << EOF
Usage: ${PROGRAM_NAME} [OPTIONS] FILE

Upload files to AWS S3 bucket.

Options:
    -h, --help                    Show this help message
    -v, --version                 Show version information
    -b, --bucket BUCKET           Specify S3 bucket (overrides default)
    -p, --path PATH               S3 path/prefix for upload
    -s, --storage-class CLASS     Storage class (default: STANDARD)
                                  Valid: ${VALID_STORAGE_CLASSES}
    --public                      Make the uploaded file publicly accessible
    --generate-url                Generate a pre-signed URL after upload
    --sync                        Enable synchronization mode
    --no-progress                 Disable progress bar
    --encrypt                     Enable client-side encryption

Examples:
    ${PROGRAM_NAME} file.txt
    ${PROGRAM_NAME} --bucket my-bucket file.txt
    ${PROGRAM_NAME} --path folder/subfolder file.txt
    ${PROGRAM_NAME} --storage-class STANDARD_IA file.txt
    ${PROGRAM_NAME} --sync --generate-url file.txt
EOF
}

# Version information
show_version() {
    show_banner
}

# Main function to handle file upload
upload_file() {
    local file_path="$1"
    local s3_path="${2:-}"
    
    show_banner
    
    # Validate file existence
    if ! validate_file "$file_path"; then
        echo "Error: File '$file_path' does not exist or is not readable."
        exit 1
    fi

    # Get file size and start upload
    local file_size=$(get_file_size "$file_path")
    echo "Uploading file: $file_path (${file_size})"
    
    # Check if file exists in S3 when sync is enabled
    if [[ "${SYNC_MODE:-false}" == "true" ]]; then
        if check_file_exists "${s3_path}/$(basename "$file_path")"; then
            read -p "File already exists in S3. Overwrite? (y/n/r[ename]): " choice
            case "$choice" in
                y|Y) ;;
                n|N) echo "Skipping upload."; return 0 ;;
                r|R) 
                    read -p "Enter new name: " new_name
                    s3_path="${s3_path}/${new_name}"
                    ;;
                *) echo "Invalid choice. Skipping upload."; return 1 ;;
            esac
        fi
    fi
    
    # Perform the upload
    if aws_upload_file "$file_path" "$s3_path"; then
        echo "✅ Upload successful!"
        
        # Generate URL if requested
        if [[ "${GENERATE_URL:-false}" == "true" ]]; then
            local url=$(generate_presigned_url "$s3_path")
            echo "📎 Presigned URL (valid for 1 hour):"
            echo "$url"
        fi
    else
        echo "❌ Upload failed!"
        exit 1
    fi
}

# Parse command line arguments
main() {
    local FILE=""
    local BUCKET=""
    local S3_PATH=""
    local STORAGE_CLASS="STANDARD"
    
    check_pv
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -b|--bucket)
                BUCKET="$2"
                shift 2
                ;;
            -p|--path)
                S3_PATH="$2"
                shift 2
                ;;
            -s|--storage-class)
                if [[ ! " $VALID_STORAGE_CLASSES " =~ " $2 " ]]; then
                    echo "Error: Invalid storage class. Valid values: $VALID_STORAGE_CLASSES"
                    exit 1
                fi
                export AWS_STORAGE_CLASS="$2"
                shift 2
                ;;
            --public)
                export MAKE_PUBLIC=true
                shift
                ;;
            --generate-url)
                export GENERATE_URL=true
                shift
                ;;
            --sync)
                export SYNC_MODE=true
                shift
                ;;
            --no-progress)
                export SHOW_PROGRESS=false
                shift
                ;;
            --encrypt)
                export CLIENT_SIDE_ENCRYPTION=true
                shift
                ;;
            -*)
                echo "Error: Unknown option $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$FILE" ]]; then
                    FILE="$1"
                else
                    echo "Error: Multiple files specified. Please upload one file at a time."
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Check if file is specified
    if [[ -z "$FILE" ]]; then
        echo "Error: No file specified"
        show_help
        exit 1
    fi

    # Override bucket if specified
    if [[ -n "$BUCKET" ]]; then
        export AWS_BUCKET_NAME="$BUCKET"
    fi

    # Perform the upload
    upload_file "$FILE" "$S3_PATH"
}

# Execute main function with all arguments
main "$@"