pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
        AWS_CREDENTIALS = credentials('aws-credentials')  // Use stored AWS credentials
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
                    sh 'cd terraform'
                    sh 'terraform init'
                    sh 'terraform plan'
                }
            }
        }

        stage('Terraform Apply - Deploy AWS Resources') {
            steps {
                script {
                    sh 'terraform apply -auto-approve'
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
                    sh 'terraform destroy -auto-approve'
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
