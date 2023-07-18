pipeline {
    // Define environment variables
    environment {
        // Image names for the server and frontend
        SERVER_IMAGE = 'red_proj_server:v1'
        FRONTEND_IMAGE = 'red_proj_frontend:v1'
        // GitHub Personal Access Token (PAT)
        GITHUB_PAT = credentials('github_pat')
        // Docker Hub login credentials
        DOCKER_USER = credentials('docker_username')
        DOCKER_PASSWORD = credentials('docker_password')
        // AWS credentials for Terraform
        AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
    }

    // run on any available Jenkins agent
    agent any
    stages {
        stage('Checkout') {
            steps {
                // Clone the repository
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: 'main']],
                    userRemoteConfigs: [[
                        url: 'https://arielfcotrim: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@github.com/arielfcotrim/red-project.git'
                        ]]
                    ])
                }
            }

        stage('Build') {
            steps {
                // Build steps for the server
                dir('server') {
                    sh 'npm install'
                }

                // Build steps for the frontend
                dir('frontend') {
                    sh 'npm install'
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
                // Build the Docker images with the Docker Hub username and repository included in the image name
                sh "docker build -t $DOCKER_USER/$SERVER_IMAGE server"
                sh "docker build -t $DOCKER_USER/$FRONTEND_IMAGE frontend"
                // Log in to Docker Hub
                sh "docker login -u $DOCKER_USER -p $DOCKER_PASSWORD"
                // Push the images to Docker Hub
                sh "docker push $DOCKER_USER/$SERVER_IMAGE"
                sh "docker push $DOCKER_USER/$FRONTEND_IMAGE"
            }
        }

        stage('Delivery') {
            steps {
                // Change to the directory containing the Terraform script
                dir('terraform') {
                    // Initialize Terraform
                    sh 'terraform init'
                    // Set the Terraform environment variables using the 'withEnv' block
                    withEnv([
                        "DOCKER_USERNAME=$DOCKER_USER",
                        "SERVER_IMAGE=$SERVER_IMAGE",
                        "FRONTEND_IMAGE=$FRONTEND_IMAGE"
                    ])
                    // Apply the Terraform script automatically
                    sh 'terraform apply -auto-approve'
                }
            }
        }
    }
}
