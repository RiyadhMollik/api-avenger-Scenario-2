#!/bin/bash

MAX_RETRIES=30
RETRY_COUNT=0
HEALTH_URL="http://localhost:3000/health"

echo "Starting health check for application..."
echo "Target: $HEALTH_URL"
echo "----------------------------------------"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)
    
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo "✓ Health check PASSED"
        echo "----------------------------------------"
        echo "Response from health endpoint:"
        curl -s $HEALTH_URL | jq '.'
        echo "----------------------------------------"
        echo "Container status:"
        docker ps | grep cicd-demo-app
        echo "----------------------------------------"
        echo "Container health:"
        docker inspect --format='{{.State.Health.Status}}' cicd-demo-app
        echo "----------------------------------------"
        echo "SUCCESS: Application is healthy and running!"
        exit 0
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Attempt $RETRY_COUNT/$MAX_RETRIES - Status: $HTTP_STATUS - Retrying in 2s..."
    sleep 2
done

echo "✗ Health check FAILED after $MAX_RETRIES attempts"
echo "----------------------------------------"
echo "Container logs:"
docker logs cicd-demo-app
exit 1
