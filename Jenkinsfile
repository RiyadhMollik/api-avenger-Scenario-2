pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'cicd-demo-app'
        IMAGE_TAG = 'latest'
        CONTAINER_NAME = 'cicd-demo-app'
        APP_PORT = '3000'
    }
    
    stages {
        stage('Cleanup') {
            steps {
                script {
                    echo 'Cleaning up previous containers and images...'
                    sh """
                        docker-compose down --remove-orphans || true
                        docker rm -f ${CONTAINER_NAME} || true
                    """
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo 'Building Docker image...'
                    sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo 'Running unit tests...'
                    sh '''
                        docker run --rm \
                        -v $(pwd)/app:/app \
                        -w /app \
                        node:18-alpine \
                        sh -c "npm install && npm test"
                    '''
                }
            }
        }
        
        stage('Package') {
            steps {
                script {
                    echo 'Verifying Docker image...'
                    sh '''
                        echo "Looking for image: ${IMAGE_NAME}:${IMAGE_TAG}"
                        docker images
                    '''
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo 'Deploying application with Docker Compose...'
                    sh 'docker-compose up -d'
                    echo 'Waiting for container to start...'
                    sleep 15
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo 'Performing health check...'
                    sh '''
                        MAX_RETRIES=30
                        RETRY_COUNT=0
                        HEALTH_URL="http://localhost:3000/health"
                        
                        echo "Starting health check for application..."
                        echo "Target: $HEALTH_URL"
                        echo "----------------------------------------"
                        
                        while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                            HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
                            
                            if [ "$HTTP_STATUS" = "200" ]; then
                                echo "✓ Health check PASSED"
                                echo "----------------------------------------"
                                echo "Response from health endpoint:"
                                curl -s "$HEALTH_URL"
                                echo ""
                                echo "----------------------------------------"
                                echo "Container status:"
                                docker ps | grep cicd-demo-app
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
                        docker logs cicd-demo-app 2>/dev/null || echo "Could not retrieve logs"
                        exit 1
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            echo 'Application is running at http://localhost:3000'
            echo 'Health endpoint: http://localhost:3000/health'
        }
        failure {
            echo 'Pipeline failed!'
            sh 'docker-compose logs'
        }
        always {
            echo 'Cleaning up workspace...'
        }
    }
}
