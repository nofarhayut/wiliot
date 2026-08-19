#!/usr/bin/env bash
# Creates the S3 bucket that holds Terraform remote state.
# Run ONCE per account, before `terraform init`. Idempotent-ish (safe to re-run).
#
#   aws sso login --profile nofar-yaba
#   AWS_PROFILE=nofar-yaba ./scripts/bootstrap-backend.sh
set -euo pipefail

REGION="us-east-1"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="wiliot-tfstate-${ACCOUNT_ID}"

echo "Account: ${ACCOUNT_ID}"
echo "Bucket:  ${BUCKET} (${REGION})"

# Create bucket. us-east-1 must NOT be given a LocationConstraint; every
# other region requires one.
if aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  echo "Bucket already exists — skipping create."
elif [ "${REGION}" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}"
else
  aws s3api create-bucket \
    --bucket "${BUCKET}" \
    --region "${REGION}" \
    --create-bucket-configuration LocationConstraint="${REGION}"
fi

# Versioning — lets us recover a corrupted/overwritten state file.
aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled

# Default server-side encryption.
aws s3api put-bucket-encryption \
  --bucket "${BUCKET}" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Block all public access — state files contain sensitive data.
aws s3api put-public-access-block \
  --bucket "${BUCKET}" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Done. Backend bucket ready: ${BUCKET}"
