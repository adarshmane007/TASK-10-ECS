#!/bin/bash
set -e

# Step 1: Generate AppSpec content
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

# Step 2: Trigger CodeDeploy deployment
DEPLOYMENT_ID=$(aws deploy create-deployment \
  --application-name strapi-codedeploy-app \
  --deployment-group-name strapi-bluegreen-group \
  --deployment-config-name CodeDeployDefault.ECSCanary10Percent5Minutes \
  --description "Blue/Green deployment triggered by GitHub Actions" \
  --revision revisionType=AppSpecContent,appSpecContent="{content=$(<deployment.yml)}" \
  --query "deploymentId" --output text)

echo "🚀 Deployment triggered: $DEPLOYMENT_ID"

# Step 3: Monitor deployment status for up to 25 minutes
echo "⏳ Monitoring deployment status for up to 25 minutes..."
for ((i=1; i<=100; i++)); do
  STATUS=$(aws deploy get-deployment \
    --deployment-id "$DEPLOYMENT_ID" \
    --query "deploymentInfo.status" --output text)
  echo "[$(date +%H:%M:%S)] Current status: $STATUS"
  if [ "$STATUS" == "Succeeded" ]; then
    echo "✅ Deployment succeeded."
    exit 0
  elif [ "$STATUS" == "Failed" ]; then
    echo "❌ Deployment failed. Check AWS Console for details."
    exit 1
  fi
  sleep 15
done

echo "⚠️ Deployment timed out after 25 minutes. Manual check recommended."
exit 1
