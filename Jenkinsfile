pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
        ECR_REPO = '823164954914.dkr.ecr.eu-west-1.amazonaws.com/internal-sales'
        IMAGE_TAG = "wagtail"
        KUBE_NAMESPACE = 'wagtail'
        HELM_RELEASE_NAME = 'wagtail-release'
        CLUSTER_NAME = 'MYAPP-EKS'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'wagtail-deployment', url: 'https://github.com/Sanchistor/DevSecOps-practice.git'
            }
        }

         stage('Authenticate to AWS ECR') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                        '''
                    }
                }
            }
        }

        stage('Build and Push Docker Image to ECR') {
            steps {
                script {
                    sh '''
                        docker build -t $ECR_REPO:$IMAGE_TAG .
                        docker push $ECR_REPO:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy to EKS using Helm') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                            aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
                            
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
            echo 'Pipeline failed. Attempting to clean up resources...'
        }
    }
}
