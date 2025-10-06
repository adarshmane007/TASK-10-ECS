##!/bin/bash

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

# Flatten content for JSON
CONTENT=$(cat deployment.yml | sed 's/"/\\"/g' | tr -d '\n')

# Create full JSON input
cat <<EOF > deploy.json
{
  "applicationName": "strapi-codedeploy-app",
  "deploymentGroupName": "strapi-bluegreen-group",
  "deploymentConfigName": "CodeDeployDefault.ECSCanary10Percent5Minutes",
  "description": "Blue/Green deployment triggered by GitHub Actions",
  "revision": {
    "type": "AppSpecContent",
    "appSpecContent": {
      "content": "$CONTENT",
      "sha256": ""
    }
  }
}
EOF

# Trigger CodeDeploy deployment
aws deploy create-deployment --cli-input-json file://deploy.json
