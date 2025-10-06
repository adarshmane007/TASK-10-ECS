#!/bin/bash
set -e

cat <<EOF > deployment.yml
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: arn:aws:ecs:ap-south-1:145065858967:task-definition/strapi-task-am-10:15
        LoadBalancerInfo:
          ContainerName: strapi
          ContainerPort: 1337
        PlatformVersion: LATEST
EOF

aws deploy create-deployment \
  --application-name strapi-codedeploy-app \
  --deployment-group-name strapi-bluegreen-group \
  --deployment-config-name CodeDeployDefault.ECSCanary10Percent5Minutes \
  --description "Blue/Green deployment triggered by GitHub Actions" \
  --revision revisionType=AppSpecContent,appSpecContent="{content=$(<deployment.yml)}"
