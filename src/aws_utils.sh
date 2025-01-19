#!/bin/bash

# AWS Utility functions for CloudUploaderCLI
# This file contains all AWS-specific operations

# Check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed. Please install it first."
        return 1
    fi

    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: AWS credentials not configured. Please run 'aws configure' first."
        return 1
    fi

    return 0
}

# Upload file to S3
aws_upload_file() {
    local file_path="$1"
    local s3_path="${2:-}"
    local bucket_name="${AWS_BUCKET_NAME:-}"

    # Validate bucket name
    if [[ -z "$bucket_name" ]]; then
        echo "Error: AWS_BUCKET_NAME not set"
        return 1
    fi

    # Check AWS CLI setup
    if ! check_aws_cli; then
        return 1
    fi

    # Construct S3 URI
    local s3_uri="s3://${bucket_name}"
    if [[ -n "$s3_path" ]]; then
        s3_uri="${s3_uri}/${s3_path}/$(basename "$file_path")"
    else
        s3_uri="${s3_uri}/$(basename "$file_path")"
    fi

    # Upload with progress
    if aws s3 cp "$file_path" "$s3_uri" --no-progress; then
        # Set public access if requested
        if [[ "${MAKE_PUBLIC:-false}" == "true" ]]; then
            aws s3api put-object-acl --bucket "$bucket_name" --key "${s3_path}/$(basename "$file_path")" --acl public-read
        fi
        return 0
    else
        return 1
    fi
}

# Generate pre-signed URL for uploaded file
generate_presigned_url() {
    local s3_path="$1"
    local bucket_name="${AWS_BUCKET_NAME:-}"
    local expiry=3600  # 1 hour

    if [[ -z "$bucket_name" ]]; then
        echo "Error: AWS_BUCKET_NAME not set"
        return 1
    fi

    # Generate pre-signed URL
    aws s3 presign "s3://${bucket_name}/${s3_path}" --expires-in "$expiry"
}

# Check if file exists in S3
check_file_exists() {
    local s3_path="$1"
    local bucket_name="${AWS_BUCKET_NAME:-}"

    if [[ -z "$bucket_name" ]]; then
        echo "Error: AWS_BUCKET_NAME not set"
        return 1
    fi

    if aws s3api head-object --bucket "$bucket_name" --key "$s3_path" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

