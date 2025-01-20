#!/bin/bash

# Validation functions for CloudUploaderCLI
# This file contains all input validation and file checking functions

# Detect OS
detect_os() {
    case "$OSTYPE" in
        msys*|cygwin*)    echo "windows" ;;
        darwin*)          echo "macos" ;;
        linux*)           echo "linux" ;;
        *)               echo "unknown" ;;
    esac
}

# Convert Windows path to Unix-style if needed
normalize_path() {
    local path="$1"
    local os=$(detect_os)
    
    if [[ "$os" == "windows" ]]; then
        # Convert Windows backslashes to forward slashes
        path="${path//\\//}"
        # Convert C: to /c
        path="/${path,}"
        path="${path/:}"
    fi
    echo "$path"
}

# Validate file existence and readability
validate_file() {
    local file_path=$(normalize_path "$1")

    # Check if file exists
    if [[ ! -f "$file_path" ]]; then
        echo "Error: File does not exist: $file_path"
        return 1
    fi

    # Check if file is readable
    if [[ ! -r "$file_path" ]]; then
        echo "Error: File is not readable: $file_path"
        return 1
    fi

    # Check if file is empty
    if [[ ! -s "$file_path" ]]; then
        echo "Warning: File is empty: $file_path"
    fi

    return 0
}

# Get file size in human-readable format
get_file_size() {
    local file_path=$(normalize_path "$1")
    local size
    local os=$(detect_os)

    case "$os" in
        windows)
            # Use Windows command to get file size
            size=$(stat -f %z "$file_path" 2>/dev/null || \
                  wmic datafile where "name='${file_path//\//\\}'" get filesize 2>/dev/null | grep -v "FileSize" | tr -d '\r\n')
            ;;
        macos)
            # macOS stat command
            size=$(stat -f %z "$file_path")
            ;;
        *)
            # Linux stat command
            size=$(stat -c %s "$file_path")
            ;;
    esac

    # Convert to human readable format
    if ((size < 1024)); then
        echo "${size} B"
    elif ((size < 1048576)); then
        echo "$(( (size + 512) / 1024 )) KB"
    elif ((size < 1073741824)); then
        echo "$(( (size + 524288) / 1048576 )) MB"
    else
        echo "$(( (size + 536870912) / 1073741824 )) GB"
    fi
}

# Validate S3 path format
validate_s3_path() {
    local s3_path="$1"

    # Remove leading/trailing slashes
    s3_path="${s3_path#/}"
    s3_path="${s3_path%/}"

    # Check for invalid characters (including Windows-specific)
    if [[ "$s3_path" =~ [^a-zA-Z0-9\-_/\.] || "$s3_path" =~ [\<\>\:\"\\|\?\*] ]]; then
        echo "Error: S3 path contains invalid characters"
        return 1
    fi

    echo "$s3_path"
    return 0
}

# Validate AWS bucket name
validate_bucket_name() {
    local bucket_name="$1"

    # Check bucket name length
    if [[ ${#bucket_name} -lt 3 || ${#bucket_name} -gt 63 ]]; then
        echo "Error: Bucket name must be between 3 and 63 characters long"
        return 1
    fi

    # Check bucket name format (including Windows considerations)
    if [[ ! "$bucket_name" =~ ^[a-z0-9][a-z0-9\.-]*[a-z0-9]$ || \
          "$bucket_name" =~ [\<\>\:\"\\|\?\*] ]]; then
        echo "Error: Invalid bucket name format"
        return 1
    fi

    return 0
}