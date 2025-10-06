#!/bin/bash

set -e

# Generate AppSpec content
cat <<EOF > deployment.yml
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

# Trigger CodeDeploy deployment using direct AppSpec content
aws deploy create-deployment \
  --application-name strapi-codedeploy-app \
  --deployment-group-name strapi-bluegreen-group \
  --deployment-config-name CodeDeployDefault.ECSCanary10Percent5Minutes \
  --description "Blue/Green deployment triggered by GitHub Actions" \
  --revision revisionType=AppSpecContent,appSpecContent="{content=$(<deployment.yml)}"
