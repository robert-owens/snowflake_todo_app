#!/bin/bash

# Snowpark Container Services Deployment Script
# Make sure you're logged into Docker and have Snowflake CLI configured

set -e

echo "🚀 Starting Snowpark Container Services Deployment..."

# Configuration
REGISTRY_HOSTNAME="advocate-mdp.registry.snowflakecomputing.com"
IMAGE_REPO="mdp_pharmacy_ws_prod/dev/todo_app_repo"
IMAGE_NAME="todo-app"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="${REGISTRY_HOSTNAME}/${IMAGE_REPO}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "📦 Building Docker image for x86_64 architecture..."
docker buildx build --platform linux/amd64 -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "🏷️  Tagging image for Snowflake registry..."
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}

echo "🔐 Logging into Snowflake Docker registry..."
echo "Please enter your Snowflake programmatic access token when prompted for password:"
echo "Note: Create a programmatic access token in Snowflake user profile → Authentication"
echo ""
docker login ${REGISTRY_HOSTNAME} -u ROBERT.L.OWENS@ADVOCATEHEALTH.ORG

echo "📤 Pushing image to Snowflake registry..."
docker push ${FULL_IMAGE_NAME}

echo "✅ Image pushed successfully!"
echo ""
echo "🔧 Next steps:"
echo "1. Run the SQL commands in deploy.sql in your Snowflake console"
echo "2. Wait for the compute pool to be ACTIVE"
echo "3. Create the service using the provided SQL"
echo "4. Check service status and get the endpoint URL"
echo ""
echo "📋 Image details:"
echo "   Registry: ${REGISTRY_HOSTNAME}"
echo "   Repository: ${IMAGE_REPO}"
echo "   Image: ${FULL_IMAGE_NAME}"