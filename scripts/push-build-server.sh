#!/usr/bin/env bash
set -euo pipefail

PROFILE="${AWS_PROFILE:-DeployDock}"
REGION="${AWS_REGION:-ap-south-1}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile|-p)
      PROFILE="$2"
      shift 2
      ;;
    --region|-r)
      REGION="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: $0 [--profile <profile>] [--region <region>]" >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
REPO_NAME="deploydock-build-worker"

echo "Describing ECR repository '$REPO_NAME' in region '$REGION' (profile: '$PROFILE')..."
REPOSITORY_URI=$(aws ecr describe-repositories \
  --repository-names "$REPO_NAME" \
  --query 'repositories[0].repositoryUri' \
  --output text \
  --profile "$PROFILE" \
  --region "$REGION" \
  --no-cli-pager)

if [[ -z "$REPOSITORY_URI" || "$REPOSITORY_URI" == "None" ]]; then
  echo "Error: Cannot find repository $REPO_NAME in ECR. Ensure the repository exists and your AWS credentials are valid." >&2
  exit 1
fi

REGISTRY="${REPOSITORY_URI%%/*}"

echo "Logging in to Amazon ECR registry '$REGISTRY'..."
aws ecr get-login-password --profile "$PROFILE" --region "$REGION" | \
  docker login --username AWS --password-stdin "$REGISTRY"

echo "Building and pushing worker image to $REPOSITORY_URI:latest..."
docker buildx build \
  --platform linux/arm64 \
  --provenance=false \
  --tag "$REPOSITORY_URI:latest" \
  --push \
  "$ROOT_DIR/build-server"

echo "Worker image published. New Fargate tasks will pull it automatically."
