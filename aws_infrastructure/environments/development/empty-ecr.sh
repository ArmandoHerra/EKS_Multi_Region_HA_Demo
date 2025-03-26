#!/bin/bash
set -euo pipefail

# Usage:
#   ./empty-ecr-all.sh <repository_name> [east|west]
# Defaults to "east" (us-east-1) if no region option is provided.
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo "Usage: $0 <repository_name> [east|west]" >&2
  exit 1
fi

REPO_NAME="$1"
REGION_OPTION="${2:-east}"
if [ "$REGION_OPTION" == "west" ]; then
  AWS_REGION="us-west-2"
else
  AWS_REGION="us-east-1"
fi

# Temporary file to hold image IDs in JSON format.
IMAGE_IDS_JSON=$(mktemp)

# List all images (both tagged and untagged) in the repository.
aws ecr list-images --region "$AWS_REGION" --no-cli-pager --no-cli-auto-prompt --repository-name "$REPO_NAME" --query 'imageIds[*]' --output json > "$IMAGE_IDS_JSON"

# Try to delete all images in a single batch.
# Capture any error output (we do not want the script to exit on failure here).
DELETE_RESULT=$(aws ecr batch-delete-image --region "$AWS_REGION" --no-cli-pager --no-cli-auto-prompt --repository-name "$REPO_NAME" --image-ids file://"$IMAGE_IDS_JSON" 2>&1 || true)

# Check if any images failed deletion due to being referenced by a manifest list.
if echo "$DELETE_RESULT" | grep -q "ImageReferencedByManifestList"; then
  echo "Some images are referenced by a manifest list. Attempting to delete the manifest lists."

  # Extract all digests from the error message.
  # The error message includes both the image digest that failed and the digest of the manifest list it is referenced by.
  # We use 'sort | uniq' to get each digest only once.
  MANIFEST_LIST_DIGESTS=$(echo "$DELETE_RESULT" | grep -oE 'sha256:[0-9a-f]{64}' | sort | uniq)

  for digest in $MANIFEST_LIST_DIGESTS; do
    echo "Deleting manifest list with digest $digest"
    # Attempt deletion of the manifest list digest.
    aws ecr batch-delete-image --region "$AWS_REGION" --no-cli-pager --no-cli-auto-prompt --repository-name "$REPO_NAME" --image-ids imageDigest="$digest" || true
  done
fi

rm -f "$IMAGE_IDS_JSON"
