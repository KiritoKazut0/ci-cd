pipeline {
    agent any

    stages {
        stage('Clonar repositorio') {
            steps {
                 git branch: 'develop', url: 'https://github.com/KiritoKazut0/ci-cd.git'
            }
        }

        stage('Instalar dependencias') {
            steps {
                sh 'npm install'
            }
        }

        stage('Probar servidor') {
            steps {
                sh 'node src/index.js & sleep 5 && curl http://localhost:3000 && kill $!'
            }
        }
    }

    post {
        success {
            echo 'Pipeline ejecutado correctamente'
        }
        failure {
            echo 'Pipeline falló'
        }
    }
}
