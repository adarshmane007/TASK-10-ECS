#!/bin/bash

set -e

# Generate AppSpec content
APPSPEC=$(cat <<EOF
version: 1
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: strapi-task-am-10
        LoadBalancerInfo:
          ContainerName: strapi
          ContainerPort: 1337
        PlatformVersion: LATEST
EOF
)

# Escape quotes and flatten content
ESCAPED_CONTENT=$(echo "$APPSPEC" | sed 's/"/\\"/g' | tr -d '\n')

# Trigger CodeDeploy deployment
aws deploy create-deployment \
  --application-name strapi-codedeploy-app \
  --deployment-group-name strapi-bluegreen-group \
  --deployment-config-name CodeDeployDefault.ECSCanary10Percent5Minutes \
  --description "Blue/Green deployment triggered by GitHub Actions" \
  --revision "revisionType=AppSpecContent,appSpecContent={\"content\":\"$ESCAPED_CONTENT\",\"sha256\":\"\"}"
