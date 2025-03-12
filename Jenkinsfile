pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
        ECR_REPO = '266735847393.dkr.ecr.eu-west-1.amazonaws.com/my-app-ecr'
        IMAGE_TAG = "wagtail"
        KUBE_NAMESPACE = 'wagtail'
        HELM_RELEASE_NAME = 'wagtail-release'
        CLUSTER_NAME = 'MYAPP-EKS'
        RDS_MASTER_USER = credentials('database-user')
        RDS_MASTER_PASSWORD = credentials('postgres-password') 
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
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
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

        stage('Create Databases in RDS') {
    steps {
        script {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                sh '''
                    export AWS_REGION=$AWS_REGION
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    # Fetch RDS Endpoint from Terraform Outputs
                    export RDS_HOST=$(aws rds describe-db-instances --query "DBInstances[0].Endpoint.Address" --output text)

                    # List of Databases to Create
                    DB_NAMES="wagtaildb aspnet_db"

                    # Create Databases in PostgreSQL
                    for DB in $DB_NAMES; do
                        PGPASSWORD=$RDS_MASTER_PASSWORD psql -h $RDS_HOST -U $RDS_MASTER_USER -d postgres -c "CREATE DATABASE $DB;"
                    done
                '''
            }
        }
    }
}


        stage('Deploy to EKS using Helm') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION

                            helm upgrade --install $HELM_RELEASE_NAME ./django-chart \
                                --namespace $KUBE_NAMESPACE \
                                --values ./django-chart/values.yaml

                            kubectl get nodes
                            kubectl get pods -A -o wide
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
