pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
        ECR_REPO = '266735847393.dkr.ecr.eu-west-1.amazonaws.com/my-app-ecr'
        IMAGE_TAG = "asp"
        KUBE_NAMESPACE = 'aspnet'
        HELM_RELEASE_NAME = 'asp-release'
        CLUSTER_NAME = 'MYAPP-EKS'
        MIGRATIONS_DIR = "Migrations" 

        //DATABASE CONFIG
        POSTGRES_DB = credentials('database_name-asp')
        POSTGRES_USER = credentials('database-user')
        POSTGRES_PASSWORD = credentials('postgres-password')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'asp-deployment', url: 'https://github.com/Sanchistor/DevSecOps-practice.git'
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

        stage('Deploy to EKS using Helm') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION

                            helm upgrade --install $HELM_RELEASE_NAME ./chart \
                                --namespace $KUBE_NAMESPACE \
                                --values ./chart/values.yaml \
                                --recreate-pods

                            echo "Waiting for pod readiness..."
                            sleep 10
                            echo "Pod is now ready!"

                        '''
                    }
                }
            }
        }
        stage('Approval Before Applying Migrations') {
            steps {
                script {
                    input message: 'Approve SQL Migrations?', ok: 'Apply Migrations'
                }
            }
        }

         stage('Fetch RDS Endpoint') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        RDS_HOST = sh(script: '''
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            aws rds describe-db-instances --query "DBInstances[0].Endpoint.Address" --output text
                        ''', returnStdout: true).trim()

                        echo "RDS Endpoint: ${RDS_HOST}"
                    }
                }
            }
        }

        stage('Apply SQL Migrations to RDS') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh """
                            export PGPASSWORD=$POSTGRES_PASSWORD
                            for sql_file in \$(ls ${MIGRATIONS_DIR}/*.sql); do
                                echo "Applying migration: \$sql_file"
                                psql -h ${RDS_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -f "\$sql_file"
                            done
                        """
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