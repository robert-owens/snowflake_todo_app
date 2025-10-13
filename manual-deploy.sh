#!/bin/bash

# Manual Deployment Steps for Snowpark Container Services
set -e

echo "🚀 Manual Snowpark Container Services Deployment..."
echo ""

# Build the image
echo "📦 Step 1: Building Docker image..."
docker build -t todo-app:latest .
echo "✅ Build complete!"
echo ""

echo "📋 Step 2: Get Registry URL from Snowflake"
echo "Run this SQL in Snowflake to get the exact registry URL:"
echo ""
echo "CREATE IMAGE REPOSITORY IF NOT EXISTS MDP_PHARMACY_WS_PROD.OPIF.todo_app_repo;"
echo "SHOW IMAGE REPOSITORIES IN SCHEMA MDP_PHARMACY_WS_PROD.OPIF;"
echo ""
echo "Copy the 'repository_url' from the output (it will look like:"
echo "orgname-accountname.registry.snowflakecomputing.com/db/schema/repo_name)"
echo ""

echo "📋 Step 3: Tag and Push Image"
echo "Replace REGISTRY_URL_FROM_STEP_2 with the actual URL from Snowflake:"
echo ""
echo "docker tag todo-app:latest REGISTRY_URL_FROM_STEP_2/todo-app:latest"
echo "docker login REGISTRY_HOSTNAME_PART"
echo "docker push REGISTRY_URL_FROM_STEP_2/todo-app:latest"
echo ""

echo "📋 Step 4: Create Service in Snowflake"
echo "Run the SQL commands in deploy.sql"
echo ""

echo "🎯 Your image is ready for tagging and pushing!"
echo "Follow the manual steps above to complete deployment."