pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                // Pull the Docker images
                sh 'docker pull red_proj_server'
                sh 'docker pull red_proj_frontend'
            }
        }
        stage('Test') {
            steps {
                // Run the Docker containers and run the tests
                sh 'docker run -d -p 3000:3000 red_proj_server'
                sh 'docker run -d -p 3001:3000 red_proj_frontend'
                sh 'cd react-express-starter/test && pytest test.py'
            }
        }
    }
}
