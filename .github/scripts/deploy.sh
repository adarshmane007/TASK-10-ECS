#!/bin/bash

set -e

# Generate AppSpec content
echo 'version: 1
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: strapi-task-am-10
        LoadBalancerInfo:
          ContainerName: strapi
          ContainerPort: 1337
        PlatformVersion: LATEST' > deployment.yml

# Escape quotes and flatten content
CONTENT=$(cat deployment.yml | sed 's/"/\\"/g' | tr -d '\n')

# Trigger CodeDeploy deployment
aws deploy create-deployment \
  --application-name strapi-codedeploy-app \
  --deployment-group-name strapi-bluegreen-group \
  --deployment-config-name CodeDeployDefault.ECSCanary10Percent5Minutes \
  --description "Blue/Green deployment triggered by GitHub Actions" \
  --revision "type=AppSpecContent,appSpecContent={\"content\":\"$CONTENT\",\"sha256\":\"\"}"
