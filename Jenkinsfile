pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
        KUBE_NAMESPACE = 'wagtail'
        KUBE_NAMESPACE_ASP = 'aspnet'
        POSTGRES_WAGTAIL_DB = credentials('database_name')
        POSTGRES_ASPNET_DB = credentials('database_name-asp')
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
                                PGPASSWORD=$POSTGRES_PASSWORD psql -h $RDS_HOST -U $POSTGRES_USER -d postgres -c "CREATE DATABASE $DB;"
                            done
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

                            #Create namespace to host wagtail application
                            kubectl create namespace $KUBE_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

                            #Create namespace to host aspnet application
                            kubectl create namespace $KUBE_NAMESPACE_ASP --dry-run=client -o yaml | kubectl apply -f -
                            
                            #Create secret to retrieve docker images from container registry for wagtail namespace
                            kubectl create secret docker-registry ecr-registry-secret \
                              --docker-server=$ECR_REPO --docker-username=AWS \
                              --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
                              --namespace=$KUBE_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
                            
                            # Create ECR secret for ASP.NET namespace
                            kubectl create secret docker-registry ecr-registry-secret \
                              --docker-server=$ECR_REPO --docker-username=AWS \
                              --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
                              --namespace=$KUBE_NAMESPACE_ASP --dry-run=client -o yaml | kubectl apply -f -

                            #Create secret for database config
                            kubectl create secret generic rds-wagtail-credentials \
                              --from-literal=POSTGRES_DB=$POSTGRES_WAGTAIL_DB \
                              --from-literal=POSTGRES_USER=$POSTGRES_USER \
                              --from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
                              --from-literal=POSTGRES_HOST=$POSTGRES_HOST \
                              --from-literal=POSTGRES_PORT=$POSTGRES_PORT \
                              --namespace=$KUBE_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

                            kubectl create secret generic rds-asp-credentials \
                              --from-literal=POSTGRES_DB=$POSTGRES_ASPNET_DB \
                              --from-literal=POSTGRES_USER=$POSTGRES_USER \
                              --from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
                              --from-literal=POSTGRES_HOST=$POSTGRES_HOST \
                              --from-literal=POSTGRES_PORT=$POSTGRES_PORT \
                              --namespace=$KUBE_NAMESPACE_ASP --dry-run=client -o yaml | kubectl apply -f -

                            #Verify creation of secrets
                            kubectl get secrets -A

                            # --------------------------------------
                            # Install NGINX Ingress Controller
                            # --------------------------------------

                            # Create namespace for Ingress
                            kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

                            # Add Helm repository for NGINX Ingress
                            helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
                            helm repo update

                            #Install ingress-nginx on K8S cluster
                            helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
                               --namespace ingress-nginx \
                               --set controller.service.type=LoadBalancer

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
