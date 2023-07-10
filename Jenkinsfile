pipeline {
    // Define environment variables
    environment {
        // Image names for the server and frontend
        SERVER_IMAGE = 'red_proj_server:v1'
        FRONTEND_IMAGE = 'red_proj_frontend:v1'
        // Ports for the server and frontend
        SERVER_PORT = '3000'
        FRONTEND_PORT = '3001'
    }

    // run on any available Jenkins agent
    agent any
    stages {
        stage('Checkout') {
            steps {
                // Clone the repository
                checkout(
                    [$class: 'GitSCM', 
                    branches: [[name: 'main']], 
                    userRemoteConfigs: [[url: 'https://github.com/arielfcotrim/red-project.git']]]
                    )
            }
        }

        stage('Build') {
            steps {
                // Build steps for the server
                dir('server') {
                    sh 'npm install'
                    // Uncomment the line below if you need to start the server
                    // sh 'npm start'
                }

                // Build steps for the frontend
                dir('frontend') {
                    sh 'npm install'
                    // Uncomment the line below if you need to start the frontend
                    // sh 'npm start'
                }
    }
}

        stage('Test') {
            steps {
                // Add the test steps for your project
            }
        }

        stage('Deployment') {
            steps {
                // Add the deployment steps for your project
            }
        }

        stage('Delivery') {
            steps {
                // Add the delivery steps for your project
            }
        }
    }
}
