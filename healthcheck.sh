#!/bin/bash

MAX_RETRIES=30
RETRY_COUNT=0
# Try container hostname first (for docker-compose internal network)
# If that fails, fall back to localhost (for host network or port-mapped access)
HEALTH_URL="http://cicd-demo-app:3000/health"
FALLBACK_URL="http://localhost:3000/health"

echo "Starting health check for application..."
echo "Target: $HEALTH_URL (or $FALLBACK_URL)"
echo "----------------------------------------"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Try container name first
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
    
    # If container name fails, try localhost
    if [ "$HTTP_STATUS" = "000" ]; then
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FALLBACK_URL" 2>/dev/null || echo "000")
    fi
    
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✓ Health check PASSED"
        echo "----------------------------------------"
        echo "Response from health endpoint:"
        curl -s "$HEALTH_URL" 2>/dev/null || curl -s "$FALLBACK_URL"
        echo ""
        echo "----------------------------------------"
        echo "Container status:"
        docker ps | grep cicd-demo-app || echo "Container not found via docker ps"
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
docker logs cicd-demo-app 2>/dev/null || echo "Could not retrieve container logs"
exit 1
