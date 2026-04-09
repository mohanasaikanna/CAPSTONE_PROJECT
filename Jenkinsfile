pipeline {
    agent any

    // ── Environment variables ────────────────────────────────────────────────
    environment {
        DOCKER_HUB_REPO    = "your-dockerhub-username/devops-capstone"
        DOCKER_HUB_CRED    = "dockerhub-credentials"       // Jenkins credential ID
        APP_EC2_HOST       = "your-app-ec2-public-ip"
        APP_EC2_USER       = "ubuntu"
        SSH_KEY_CRED       = "ec2-ssh-key"                 // Jenkins credential ID
        IMAGE_TAG          = "${BUILD_NUMBER}"
        CONTAINER_NAME     = "capstone-app"
        APP_PORT           = "3000"
    }

    // ── Pipeline options ────────────────────────────────────────────────────
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        timestamps()
    }

    // ── Trigger: poll GitHub every minute ───────────────────────────────────
    triggers {
        pollSCM('* * * * *')
    }

    stages {

        // ── Stage 1: Checkout ───────────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo "Checking out source code from GitHub..."
                checkout scm
                sh 'git log --oneline -5'
            }
        }

        // ── Stage 2: Install dependencies ───────────────────────────────────
        stage('Install Dependencies') {
            steps {
                dir('app') {
                    echo "Installing Node.js dependencies..."
                    sh 'node --version'
                    sh 'npm --version'
                    sh 'npm ci'
                }
            }
        }

        // ── Stage 3: Run tests ───────────────────────────────────────────────
        stage('Test') {
            steps {
                dir('app') {
                    echo "Running unit tests..."
                    sh 'npm test -- --forceExit'
                }
            }
            post {
                always {
                    // Publish test results if junit reporter is configured
                    echo "Tests completed."
                }
            }
        }

        // ── Stage 4: Build Docker image ──────────────────────────────────────
        stage('Build Docker Image') {
            steps {
                dir('app') {
                    echo "Building Docker image: ${DOCKER_HUB_REPO}:${IMAGE_TAG}"
                    sh """
                        docker build \
                          --tag ${DOCKER_HUB_REPO}:${IMAGE_TAG} \
                          --tag ${DOCKER_HUB_REPO}:latest \
                          --label "build=${BUILD_NUMBER}" \
                          --label "git-commit=${GIT_COMMIT}" \
                          .
                    """
                    sh "docker images | grep ${DOCKER_HUB_REPO}"
                }
            }
        }

        // ── Stage 5: Push image to Docker Hub ───────────────────────────────
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_HUB_CRED}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    echo "Pushing image to Docker Hub..."
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                    sh "docker push ${DOCKER_HUB_REPO}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_HUB_REPO}:latest"
                    sh "docker logout"
                }
            }
        }

        // ── Stage 6: Deploy to App EC2 ───────────────────────────────────────
        stage('Deploy to EC2') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: "${SSH_KEY_CRED}",
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    echo "Deploying container on App EC2: ${APP_EC2_HOST}"
                    sh """
                        ssh -o StrictHostKeyChecking=no \
                            -i ${SSH_KEY} \
                            ${APP_EC2_USER}@${APP_EC2_HOST} \
                        '
                            echo "--- Pulling latest image ---"
                            docker pull ${DOCKER_HUB_REPO}:${IMAGE_TAG}

                            echo "--- Stopping old container (if any) ---"
                            docker stop ${CONTAINER_NAME} 2>/dev/null || true
                            docker rm   ${CONTAINER_NAME} 2>/dev/null || true

                            echo "--- Starting new container ---"
                            docker run -d \
                              --name ${CONTAINER_NAME} \
                              --restart unless-stopped \
                              -p ${APP_PORT}:3000 \
                              -e NODE_ENV=production \
                              ${DOCKER_HUB_REPO}:${IMAGE_TAG}

                            echo "--- Container status ---"
                            docker ps | grep ${CONTAINER_NAME}
                        '
                    """
                }
            }
        }

        // ── Stage 7: Health check ────────────────────────────────────────────
        stage('Health Check') {
            steps {
                echo "Waiting 15s for container to start..."
                sh 'sleep 15'
                withCredentials([sshUserPrivateKey(
                    credentialsId: "${SSH_KEY_CRED}",
                    keyFileVariable: 'SSH_KEY'
                )]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no \
                            -i ${SSH_KEY} \
                            ${APP_EC2_USER}@${APP_EC2_HOST} \
                        '
                            STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${APP_PORT}/health)
                            echo "Health check HTTP status: $STATUS"
                            if [ "$STATUS" != "200" ]; then
                              echo "Health check FAILED!"
                              exit 1
                            fi
                            echo "Health check PASSED!"
                        '
                    """
                }
            }
        }

        // ── Stage 8: Clean up old Docker images ──────────────────────────────
        stage('Cleanup') {
            steps {
                echo "Removing dangling Docker images from Jenkins host..."
                sh 'docker image prune -f'
            }
        }
    }

    // ── Post actions ─────────────────────────────────────────────────────────
    post {
        success {
            echo "Pipeline SUCCESS — Build #${BUILD_NUMBER} deployed to ${APP_EC2_HOST}:${APP_PORT}"
        }
        failure {
            echo "Pipeline FAILED — Check console output above."
        }
        always {
            echo "Build duration: ${currentBuild.durationString}"
        }
    }
}
