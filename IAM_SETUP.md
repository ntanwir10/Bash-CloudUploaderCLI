# IAM User Setup Instructions for CloudUploaderCLI

## 1. Create IAM User

```bash
aws iam create-user --user-name clouduploader-cli-user
```

## 2. Create and Attach Policy

1. Save the IAM policy from `iam_user_policy.json` to AWS:
```bash
aws iam create-policy \
    --policy-name CloudUploaderCLIPolicy \
    --policy-document file://iam_user_policy.json
```

2. Attach the policy to the user:
```bash
aws iam attach-user-policy \
    --user-name clouduploader-cli-user \
    --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/CloudUploaderCLIPolicy
```

## 3. Create Access Keys

```bash
aws iam create-access-key --user-name clouduploader-cli-user
```

## 4. Configure Credentials

1. Copy `.env.template` to `.env`:
```bash
cp .env.template .env
```

2. Update `.env` with the access keys:
```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_DEFAULT_REGION=us-east-1
```

## Security Best Practices

1. **Access Key Rotation**:
   - Rotate access keys every 90 days
   - Use `aws iam create-access-key` to create new keys
   - Use `aws iam delete-access-key` to remove old keys

2. **Permissions**:
   - The user has minimal required permissions
   - All actions require HTTPS (SecureTransport)
   - Server-side encryption is enforced

3. **Monitoring**:
   - Enable AWS CloudTrail for API activity logging
   - Monitor IAM user activity regularly

## Permission Details

### S3 Permissions:
- `s3:PutObject`: Upload files
- `s3:GetObject`: Download and verify files
- `s3:ListBucket`: Check file existence and list contents
- `s3:DeleteObject`: Manage file overwrites
- `s3:PutObjectAcl`: Manage file permissions

### KMS Permissions:
- `kms:GenerateDataKey`: Generate keys for encryption
- `kms:Decrypt`: Decrypt files when needed

### Additional Permissions:
- `s3:ListAllMyBuckets`: List available buckets (optional)

## Troubleshooting

1. **Access Denied Errors**:
   - Verify AWS credentials in `.env`
   - Check bucket name matches policy
   - Ensure HTTPS is being used

2. **Encryption Errors**:
   - Verify KMS key permissions
   - Check encryption settings in request

3. **Permission Issues**:
   - Review CloudTrail logs for denied actions
   - Verify policy is attached correctly 