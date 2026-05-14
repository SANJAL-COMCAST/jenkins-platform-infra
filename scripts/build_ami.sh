#!/bin/bash

set -e

REGION="ap-south-1"

PIPELINE_ARN="arn:aws:imagebuilder:ap-south-1:272916400173:image-pipeline/jenkins-agent-al2023-pipeline"

mkdir -p output

echo "Starting Image Builder pipeline..."

BUILD_ARN=$(aws imagebuilder start-image-pipeline-execution \
  --image-pipeline-arn $PIPELINE_ARN \
  --region $REGION \
  --query 'imageBuildVersionArn' \
  --output text)

echo "$BUILD_ARN" > output/build_arn.txt

echo "Build ARN:"
echo "$BUILD_ARN"