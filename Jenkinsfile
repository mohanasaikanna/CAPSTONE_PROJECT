pipeline {
    agent any

    stages {

        stage('Clone Code') {
            steps {
                git 'https://github.com/YOUR_USERNAME/YOUR_REPO.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t capstone-app .'
            }
        }

        stage('Deploy Container') {
            steps {
                sh '''
                docker stop capstone-app || true
                docker rm capstone-app || true
                docker run -d -p 3000:3000 --name capstone-app capstone-app
                '''
            }
        }
    }
}
