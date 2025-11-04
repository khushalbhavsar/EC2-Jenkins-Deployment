pipeline {
    agent any

    stages {
        stage('dev') {
            steps {
                echo 'I am in Dev'
                sh 'git --version'
            }
        }
    stage('prod') {
            steps {
                echo 'I am in prod'
                sh 'docker --version'
            }
        }
    }
}
