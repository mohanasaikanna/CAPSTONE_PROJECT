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
                sh "docker build -t $IMAGE_NAME:latest ."
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
                sh """
                docker stop $CONTAINER_NAME || true
                docker rm $CONTAINER_NAME || true
                docker run -d -p 3000:3000 --name $CONTAINER_NAME $IMAGE_NAME:latest
                """
            }
        }
    }
}
