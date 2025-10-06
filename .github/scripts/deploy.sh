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

# Flatten and escape content
CONTENT=$(tr -d '\n' < deployment.yml | sed 's/"/\\"/g')

# Create JSON payload
cat <<EOF > deploy.json
{
  "applicationName": "strapi-codedeploy-app",
  "deploymentGroupName": "strapi-bluegreen-group",
  "deploymentConfigName": "CodeDeployDefault.ECSCanary10Percent5Minutes",
  "description": "Blue/Green deployment triggered by GitHub Actions",
  "revision": {
    "revisionType": "AppSpecContent",
    "appSpecContent": {
      "content": "$CONTENT"
    }
  }
}
EOF

# Trigger deployment
aws deploy create-deployment --cli-input-json file://deploy.json
# trigger deploy
