pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
        AWS_CREDENTIALS = 'aws-credentials'  // ID of your AWS credentials stored in Jenkins
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'provion-resources', url: 'https://github.com/Sanchistor/DevSecOps-practice.git'
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS) {
                        // Ensure Terraform commands can access AWS resources
                        sh 'cd terraform'
                        sh 'terraform init'
                        sh 'terraform plan'
                    }
                }
            }
        }

        stage('Terraform Apply - Deploy AWS Resources') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS) {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Approval for Destroy') {
            steps {
                input message: 'Do you want to destroy AWS resources?', ok: 'Destroy'
            }
        }

        stage('Terraform Destroy - Clean Up AWS Resources') {
            steps {
                script {
                    withAWS(credentials: AWS_CREDENTIALS) {
                        sh 'terraform destroy -auto-approve'
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline execution completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs!'
        }
    }
}
