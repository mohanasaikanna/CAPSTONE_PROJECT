pipeline {
    agent any

    environment {
        IMAGE_NAME = "saikanna14/devops-app"
        CONTAINER_NAME = "capstone-app"
    }

    stages {

        stage('Clone Code') {
            steps {
                git 'https://github.com/mohanasaikanna/CAPSTONE_PROJECT.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('app') {
                    sh "docker build -t $IMAGE_NAME:latest ."
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh 'echo $PASS | docker login -u $USER --password-stdin'
                }
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
                sh "docker push $IMAGE_NAME:latest"
            }
        }

        stage('Deploy Container') {
            steps {
                sh '''
                echo "Cleaning port 3000..."

                docker ps -q --filter "publish=3000" | xargs -r docker stop || true
                docker ps -q --filter "publish=3000" | xargs -r docker rm || true

                echo "Starting container..."
                docker run -d -p 3000:3000 --name capstone-app saikanna14/devops-app:latest
                '''
            }
        }
    }
}
