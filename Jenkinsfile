pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
        KUBE_NAMESPACE = 'wagtail'
        POSTGRES_DB = credentials('database_name')
        POSTGRES_USER = credentials('database-user')
        POSTGRES_PASSWORD = credentials('postgres-password') 
        POSTGRES_PORT = credentials('postgres-port') 
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
                            terraform output -raw ecr_repository_url > ../ecr_url.txt
                            terraform output -raw eks_name > ../cluster_name.txt
                            terraform output -raw rds_endpoint > ../rds_endpoint.txt
                        '''
                    }
                }
            }
        }

        stage('Setup Kubernetes Cluster') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                            # Load ECR Repository URL and EKS cluster name
                            export ECR_REPO=$(cat ecr_url.txt)
                            export CLUSTER_NAME=$(cat cluster_name.txt)
                            export POSTGRES_HOST=$(cat rds_endpoint.txt)

                            echo "Using ECR Repo: $ECR_REPO"
                            echo "Using Cluster: $CLUSTER_NAME"
                            echo "Using RDS: $POSTGRES_HOST"

                            # Login to AWS CLI and connect to kubernetes cluster
                            export AWS_REGION=$AWS_REGION 
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION

                            #Create namespace to host application
                            kubectl create namespace $KUBE_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
                            
                            #Create secret to retrieve docker images from container registry
                            kubectl create secret docker-registry ecr-registry-secret \
                              --docker-server=$ECR_REPO \
                              --docker-username=AWS \
                              --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
                              --namespace=$KUBE_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

                            #Create secret for database config
                            kubectl create secret generic rds-credentials \
                              --from-literal=POSTGRES_DB=$POSTGRES_DB \
                              --from-literal=POSTGRES_USER=$POSTGRES_USER \
                              --from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
                              --from-literal=POSTGRES_HOST=$POSTGRES_HOST \
                              --from-literal=POSTGRES_PORT=$POSTGRES_PORT \
                              --namespace=$KUBE_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

                            #Verify creation of secrets
                            kubectl get secrets -n $KUBE_NAMESPACE
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
            echo 'Pipeline failed. Attempting to clean up resources...'
            script {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    sh '''
                        export AWS_REGION=$AWS_REGION
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        cd terraform
                        terraform destroy -auto-approve || true
                    '''
                }
            }
        }
    }
}
