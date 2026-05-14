#!/bin/bash

set -e

REGION="ap-south-1"

BUILD_ARN=$(cat output/build_arn.txt)

echo "Waiting for AMI build completion..."

while true
do

  STATUS=$(aws imagebuilder get-image \
    --image-build-version-arn $BUILD_ARN \
    --region $REGION \
    --query 'image.state.status' \
    --output text)

  echo "Current Status: $STATUS"

  if [ "$STATUS" = "AVAILABLE" ]; then
    break
  fi

  if [ "$STATUS" = "FAILED" ]; then
    echo "AMI build failed"
    exit 1
  fi

  sleep 30

done

AMI_ID=$(aws imagebuilder get-image \
  --image-build-version-arn $BUILD_ARN \
  --region $REGION \
  --query 'image.outputResources.amis[0].image' \
  --output text)

echo "$AMI_ID" > output/ami.txt

echo "AMI Created:"
echo "$AMI_ID"