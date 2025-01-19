#!/bin/bash

# CloudUploaderCLI - A tool for uploading files to AWS S3
# Author: Noman Tanwir
# Version: 1.0.0

set -e  # Exit on error
set -u  # Exit on undefined variable

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/aws_utils.sh"
source "${SCRIPT_DIR}/validation.sh"

# Constants
PROGRAM_NAME="clouduploader"
VERSION="1.0.0"

# Help message
show_help() {
    cat << 'EOF'
Usage: ${PROGRAM_NAME} [OPTIONS] FILE

Upload files to AWS S3 bucket.

Options:
    -h, --help              Show this help message
    -v, --version           Show version information
    -b, --bucket BUCKET     Specify S3 bucket (overrides default)
    -p, --path PATH        S3 path/prefix for upload
    --public               Make the uploaded file publicly accessible
    --generate-url         Generate a pre-signed URL after upload

Examples:
    ${PROGRAM_NAME} file.txt
    ${PROGRAM_NAME} --bucket my-bucket file.txt
    ${PROGRAM_NAME} --path folder/subfolder file.txt
EOF
}

# Version information
show_version() {
    echo "${PROGRAM_NAME} version ${VERSION}"
}

# Main function to handle file upload
upload_file() {
    local file_path="$1"
    local s3_path="${2:-}"
    
    # Validate file existence
    if ! validate_file "$file_path"; then
        echo "Error: File '$file_path' does not exist or is not readable."
        exit 1
    }

    # Get file size and start upload
    local file_size=$(get_file_size "$file_path")
    echo "Uploading file: $file_path (${file_size} bytes)"
    
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
            --public)
                export MAKE_PUBLIC=true
                shift
                ;;
            --generate-url)
                export GENERATE_URL=true
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