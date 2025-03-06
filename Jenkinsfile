pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
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
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            cd terraform
                            ls -al
                            terraform init
                            terraform plan
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply - Deploy AWS Resources') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            cd terraform
                            terraform apply -auto-approve
                        '''
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
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            cd terraform
                            terraform destroy -auto-approve
                        '''
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
