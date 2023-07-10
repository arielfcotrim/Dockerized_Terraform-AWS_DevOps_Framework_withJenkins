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
                // Go into the tests directory
                dir('tests') {
                    // Install requirements
                    sh 'pip install -r requirements.txt'
                    // Run the test.py file
                    sh 'pytest -m test.py'
                }
            }
        }

        stage('Deployment') {
            steps {
                // Build the Docker images
                sh 'docker build -t $SERVER_IMAGE server'
                sh 'docker build -t $FRONTEND_IMAGE frontend'
                // Run the Docker containers
                sh "docker run -d -p $SERVER_PORT:3000 --name red_proj_server $SERVER_IMAGE"
                sh "docker run -d -p $FRONTEND_PORT:3000 --name red_proj_frontend $FRONTEND_IMAGE"
            }
        }

        stage('Delivery') {
            steps {
                // Add the delivery steps for your project
            }
        }
    }
}
