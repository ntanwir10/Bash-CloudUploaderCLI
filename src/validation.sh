#!/bin/bash

# Validation functions for CloudUploaderCLI
# This file contains all input validation and file checking functions

# Validate file existence and readability
validate_file() {
    local file_path="$1"

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
    local file_path="$1"
    local size

    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        size=$(stat -f %z "$file_path")
    else
        # Linux
        size=$(stat -c %s "$file_path")
    fi

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

    # Check for invalid characters
    if [[ "$s3_path" =~ [^a-zA-Z0-9\-_/\.] ]]; then
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

    # Check bucket name format
    if [[ ! "$bucket_name" =~ ^[a-z0-9][a-z0-9\.-]*[a-z0-9]$ ]]; then
        echo "Error: Invalid bucket name format"
        return 1
    fi

    return 0
}