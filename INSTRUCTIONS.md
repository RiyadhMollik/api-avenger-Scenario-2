# CI/CD Pipeline - Complete Setup Instructions

## Prerequisites

- Docker Desktop installed and running
- Git installed
- Internet connection

## Part 1: Quick Local Test (5 minutes)

### Step 1: Clone and Test Application

```powershell
cd "E:\api avenger"

docker-compose up -d

Start-Sleep -Seconds 5

curl http://localhost:3000
curl http://localhost:3000/health

docker-compose down
```

Expected output: JSON responses from both endpoints.

## Part 2: Jenkins Setup with Docker-in-Docker (10 minutes)

### Step 2: Start Jenkins Container

```powershell
docker run -d `
  --name jenkins `
  --privileged `
  -p 8080:8080 `
  -p 50000:50000 `
  -v jenkins_home:/var/jenkins_home `
  -v /var/run/docker.sock:/var/run/docker.sock `
  jenkins/jenkins:lts
```

### Step 3: Install Docker Tools in Jenkins

```powershell
docker exec -u root jenkins sh -c "apt-get update && apt-get install -y docker.io docker-compose curl"

docker exec -u root jenkins usermod -aG docker jenkins

docker restart jenkins
```

### Step 4: Get Jenkins Password

```powershell
Start-Sleep -Seconds 30

docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Copy the password shown in terminal.

## Part 3: Jenkins UI Setup (5 minutes)

### Step 5: Access Jenkins

1. Open browser: http://localhost:8080
2. Paste the password from Step 4
3. Click "Install suggested plugins"
4. Wait for plugins to install
5. Create admin user:
   - Username: admin
   - Password: admin123
   - Full name: Admin
   - Email: admin@localhost
6. Click "Save and Continue"
7. Keep default Jenkins URL
8. Click "Start using Jenkins"

### Step 6: Create Pipeline Job

1. Click "New Item"
2. Enter name: `CICD-Demo-Pipeline`
3. Select "Pipeline"
4. Click "OK"

### Step 7: Configure Pipeline

1. Scroll to "Pipeline" section
2. Definition: Select "Pipeline script"
3. Paste the following script:

```groovy
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
                    sh '''
                        docker-compose down --remove-orphans || true
                        docker rm -f ${CONTAINER_NAME} || true
                    '''
                }
            }
        }
        
        stage('Checkout') {
            steps {
                script {
                    echo 'Cloning repository...'
                    git branch: 'main', url: 'https://github.com/RiyadhMollik/api-avenger-Scenario-2.git'
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
                    sh 'docker images | grep ${IMAGE_NAME}'
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
                    sh '''
                        for i in {1..30}; do
                            HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)
                            if [ "$HTTP_STATUS" -eq 200 ]; then
                                echo "✓ Health check PASSED"
                                echo "Response:"
                                curl -s http://localhost:3000/health
                                echo ""
                                echo "Container status:"
                                docker ps | grep cicd-demo-app
                                echo "SUCCESS: Application is healthy!"
                                exit 0
                            fi
                            echo "Attempt $i/30 - Status: $HTTP_STATUS - Retrying..."
                            sleep 2
                        done
                        echo "✗ Health check FAILED"
                        docker logs cicd-demo-app
                        exit 1
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo '=========================================='
            echo 'Pipeline completed successfully!'
            echo 'Application URL: http://localhost:3000'
            echo 'Health endpoint: http://localhost:3000/health'
            echo '=========================================='
        }
        failure {
            echo 'Pipeline failed!'
            sh 'docker-compose logs || true'
        }
    }
}
```

4. Click "Save"

## Part 4: Run Pipeline & Capture Output (5 minutes)

### Step 8: Execute Pipeline

1. Click "Build Now" in left sidebar
2. Watch build appear under "Build History"
3. Build will show as "#1"
4. Click on "#1"

### Step 9: Take Screenshots

**Screenshot 1 - Stage View:**
- Take screenshot showing all 7 stages
- Should show: Cleanup → Checkout → Build → Test → Package → Deploy → Health Check
- All stages should be GREEN

**Screenshot 2 - Console Output:**
1. Click "Console Output" in left sidebar
2. Let it scroll to the bottom
3. Take screenshot showing:
   - Test results (2 tests passed)
   - Health check PASSED
   - "SUCCESS: Application is healthy!"
   - "Finished: SUCCESS"

**Screenshot 3 - Pipeline Overview:**
- Go back to main pipeline page
- Take screenshot showing successful build history

### Step 10: Verify Application

```powershell
docker ps | findstr cicd-demo-app

curl http://localhost:3000

curl http://localhost:3000/health
```

**Screenshot 4 - Application Response:**
- Take screenshot of browser showing:
  - http://localhost:3000
  - http://localhost:3000/health

## Expected Console Output

```
Started by user admin
Running in Durability level: MAX_SURVIVABILITY
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /var/jenkins_home/workspace/CICD-Demo-Pipeline
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Cleanup)
[Pipeline] echo
Cleaning up previous containers and images...
[Pipeline] sh
+ docker-compose down --remove-orphans
+ docker rm -f cicd-demo-app
[Pipeline] }
[Pipeline] stage
[Pipeline] { (Checkout)
[Pipeline] echo
Cloning repository...
[Pipeline] git
Cloning into workspace...
[Pipeline] }
[Pipeline] stage
[Pipeline] { (Build)
[Pipeline] echo
Building Docker image...
[Pipeline] sh
+ docker build -t cicd-demo-app:latest .
Successfully built 1a2b3c4d5e6f
Successfully tagged cicd-demo-app:latest
[Pipeline] }
[Pipeline] stage
[Pipeline] { (Test)
[Pipeline] echo
Running unit tests...
[Pipeline] sh
+ npm install
+ npm test
PASS ./server.test.js
  API Endpoints
    ✓ GET / should return welcome message
    ✓ GET /health should return healthy status

Tests:       2 passed, 2 total
[Pipeline] }
[Pipeline] stage
[Pipeline] { (Package)
[Pipeline] echo
Verifying Docker image...
cicd-demo-app    latest    1a2b3c4d5e6f
[Pipeline] }
[Pipeline] stage
[Pipeline] { (Deploy)
[Pipeline] echo
Deploying application with Docker Compose...
[Pipeline] sh
Creating network "api-avenger_default" with the default driver
Creating cicd-demo-app ... done
[Pipeline] }
[Pipeline] stage
[Pipeline] { (Health Check)
[Pipeline] echo
Performing health check...
[Pipeline] sh
Attempt 1/30 - Status: 000 - Retrying...
Attempt 2/30 - Status: 200 - Success!
✓ Health check PASSED
Response:
{"status":"healthy","uptime":5.234,"timestamp":"2025-11-13T10:30:45.123Z"}

Container status:
1a2b3c4d5e6f   cicd-demo-app:latest   "node server.js"   Up 10 seconds   0.0.0.0:3000->3000/tcp   cicd-demo-app

SUCCESS: Application is healthy!
[Pipeline] }
[Pipeline] stage
[Pipeline] { (Declarative: Post Actions)
[Pipeline] echo
==========================================
Pipeline completed successfully!
Application URL: http://localhost:3000
Health endpoint: http://localhost:3000/health
==========================================
[Pipeline] }
[Pipeline] }
[Pipeline] End of Pipeline
Finished: SUCCESS
```

## Part 5: Cleanup (Optional)

### Stop Application Only

```powershell
docker-compose down
```

### Stop Everything Including Jenkins

```powershell
docker-compose down
docker stop jenkins
docker rm jenkins
docker volume rm jenkins_home
docker system prune -f
```

## Troubleshooting

### Issue: Jenkins can't access Docker

```powershell
docker exec -u root jenkins usermod -aG docker jenkins
docker restart jenkins
```

### Issue: Port 8080 already in use

```powershell
docker run -d --name jenkins --privileged -p 9090:8080 ...
```
Then access at http://localhost:9090

### Issue: Container won't start

```powershell
docker logs cicd-demo-app
docker-compose logs
```

### Issue: Health check fails

```powershell
docker ps
docker logs cicd-demo-app
curl -v http://localhost:3000/health
```

## Summary Checklist

- [ ] Docker Desktop running
- [ ] Jenkins container started
- [ ] Jenkins accessible at http://localhost:8080
- [ ] Pipeline created and configured
- [ ] Pipeline executed successfully
- [ ] All 7 stages completed (GREEN)
- [ ] Application accessible at http://localhost:3000
- [ ] Health endpoint returns status 200
- [ ] Screenshots captured (4 screenshots)
- [ ] Console output copied

## Screenshots Required for Submission

1. Jenkins Stage View (all stages green)
2. Console Output (showing success)
3. Pipeline Overview (build history)
4. Application Response (browser showing endpoints)

Total Time: ~25 minutes
