# CI/CD Deployment Pipeline

Complete CI/CD pipeline using Jenkins, Docker, and Docker Compose.

## Project Structure

```
.
├── app/
│   ├── server.js
│   ├── server.test.js
│   └── package.json
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile
├── healthcheck.sh
└── README.md
```

## Prerequisites

- Docker installed
- Docker Compose installed
- Jenkins with Docker installed (for pipeline execution)

## Quick Start

### Option 1: Run with Docker Compose

```bash
docker-compose up -d
```

Access the application at `http://localhost:3000`

### Option 2: Run Jenkins Pipeline

1. **Start Jenkins in Docker (Docker-in-Docker)**

```bash
docker run -d \
  --name jenkins \
  --privileged \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

2. **Install Docker in Jenkins Container**

```bash
docker exec -u root jenkins sh -c "apt-get update && apt-get install -y docker.io docker-compose"
docker exec -u root jenkins usermod -aG docker jenkins
docker restart jenkins
```

3. **Access Jenkins**

- URL: `http://localhost:8080`
- Get initial password: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`

4. **Create Pipeline Job**

- New Item → Pipeline
- Configure → Pipeline → Definition: Pipeline script from SCM
- Or paste Jenkinsfile content directly

5. **Run Pipeline**

Click "Build Now" to execute the pipeline.

## Pipeline Stages

1. **Cleanup** - Remove previous containers
2. **Build** - Build Docker image
3. **Test** - Run unit tests
4. **Package** - Verify Docker image
5. **Deploy** - Deploy with Docker Compose
6. **Health Check** - Verify application health

## API Endpoints

- `GET /` - Welcome message
- `GET /health` - Health status

## Testing

Run tests locally:

```bash
cd app
npm install
npm test
```

## Health Check

```bash
chmod +x healthcheck.sh
./healthcheck.sh
```

## Stop Application

```bash
docker-compose down
```

## Cleanup

```bash
docker-compose down --rmi all --volumes
docker system prune -f
```
