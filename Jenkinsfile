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
                    sh "docker images | grep \${IMAGE_NAME}"
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo 'Deploying application with Docker Compose...'
                    sh 'docker-compose up -d'
                    echo 'Waiting for container to start...'
                    sleep 10
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo 'Performing health check...'
                    sh 'chmod +x healthcheck.sh'
                    sh './healthcheck.sh'
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
