#!/bin/bash

set -e

REGION="ap-south-1"

AMI_ID=$(cat output/ami.txt)

echo "Publishing latest AMI to SSM..."

aws ssm put-parameter \
  --name "/jenkins/agent/latest-ami" \
  --value "$AMI_ID" \
  --type String \
  --overwrite \
  --region $REGION

echo "Published AMI:"
echo "$AMI_ID"