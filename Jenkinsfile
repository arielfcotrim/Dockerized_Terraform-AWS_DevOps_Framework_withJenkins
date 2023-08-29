pipeline {
    // Define environment variables
    environment {
        // Image names for the server and frontend
        SERVER_IMAGE = "red_proj_server:v1"
        FRONTEND_IMAGE = "red_proj_frontend:v1"
        // Docker Hub login credentials
        DOCKER_USERNAME = credentials('docker_username')
        DOCKER_PASSWORD = credentials('docker_password')
        // AWS credentials for Terraform
        AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
    }

    // run on any available Jenkins agent
    agent any
    stages {
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
                dir('test') {
                    // Install requirements
                    sh 'pip install -r requirements.txt'
                    // Run the test.py file
                    sh 'python3 -m pytest test.py'
                }
            }
        }

        stage('Deployment') {
            steps {
                // Build the Docker images with the Docker Hub username and repository included in the image name
                sh "docker build -t $DOCKER_USERNAME/$SERVER_IMAGE server"
                sh "docker build -t $DOCKER_USERNAME/$FRONTEND_IMAGE frontend"
                // Log in to Docker Hub
                sh "docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD"
                // Push the images to Docker Hub
                sh "docker push $DOCKER_USERNAME/$SERVER_IMAGE"
                sh "docker push $DOCKER_USERNAME/$FRONTEND_IMAGE"
            }
        }

        stage('Delivery') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    withEnv([
                        "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}",
                        "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}",
                        "DOCKER_USERNAME=${DOCKER_USERNAME}",
                        "SERVER_IMAGE=${SERVER_IMAGE}",
                        "FRONTEND_IMAGE=${FRONTEND_IMAGE}"
                ]) {
                    sh '''\\
                        export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                        export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                        export DOCKER_USERNAME=${DOCKER_USERNAME}
                        export SERVER_IMAGE=${SERVER_IMAGE}
                        export FRONTEND_IMAGE=${FRONTEND_IMAGE}

                        terraform apply -auto-approve \
                        -var "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
                        -var "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
                        -var "DOCKER_USERNAME=${DOCKER_USERNAME}" \
                        -var "SERVER_IMAGE=${SERVER_IMAGE}" \
                        -var "FRONTEND_IMAGE=${FRONTEND_IMAGE}"
                    '''
                    }
                }
            }
        }
    }
}
