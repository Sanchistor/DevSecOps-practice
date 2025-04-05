pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
        ECR_REPO = '266735847393.dkr.ecr.eu-west-1.amazonaws.com/my-app-ecr'
        IMAGE_TAG = "asp"
        KUBE_NAMESPACE = 'aspnet'
        HELM_RELEASE_NAME = 'asp-release'
        CLUSTER_NAME = 'MYAPP-EKS'
        PROJECT_TECHNOLOGY = 'AspNet'

        //DATABASE CONFIG
        MIGRATIONS_DIR = "Migrations" 
        POSTGRES_DB = credentials('database_name-asp')
        POSTGRES_USER = credentials('database-user')
        POSTGRES_PASSWORD = credentials('postgres-password')
        
        //Migrations approve stage env
        PROCEED_WITH_MIGRATIONS = 'false'

        //Security tools creedentials
        SNYK_TOKEN = credentials('SNYK_TOKEN')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'asp-deployment', url: 'https://github.com/Sanchistor/DevSecOps-practice.git'
            }
        }

        stage('Run Snyk Test') {
            steps {
                withCredentials([
                    string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
                ]) {
                    script {
                        // Check if the csproj file exists to ensure we're testing the right file
                        sh 'ls -l riga.services.csproj'

                        // Running snyk test and capturing output for debugging
                        try {
                            echo "Running snyk test..."
                            def snykResult = sh(script: 'snyk test --file=riga.services.csproj --debug --json', returnStdout: true, returnStatus: true)

                            echo "Snyk test output: ${snykResult}"
                            if (snykResult != 0) {
                                error("Snyk test failed with exit code ${snykResult}. Please check the report for errors.")
                            }

                            // Archive the Snyk report for further inspection
                            archiveArtifacts artifacts: 'snyk-report.json', fingerprint: true

                            // Extract vulnerabilities count from the Snyk report using jq
                            def snykVulnerabilityCount = sh(script: 'jq ".vulnerabilities | length" snyk-report.json', returnStdout: true).trim()
                            echo "Number of vulnerabilities found by Snyk: ${snykVulnerabilityCount}"

                            // Prepare JSON payload for Lambda
                            sh """
                                jq -c --arg build_number "$BUILD_ID" --arg language "$PROJECT_TECHNOLOGY" '{
                                    application_language: \$language,
                                    build_number: \$build_number,
                                    test_type: "SnykTest",
                                    version: "1.114.0",
                                    results: .vulnerabilities
                                }' snyk-report.json > lambda-snyk-payload.json
                            """

                            archiveArtifacts artifacts: 'lambda-snyk-payload.json', fingerprint: true

                            // Uncomment if invoking Lambda and sending data to CloudWatch
                            // Ensure the payload is valid and send it to Lambda
                            // ...
                        } catch (Exception e) {
                            echo "An error occurred during the Snyk test: ${e.message}"
                            currentBuild.result = 'FAILURE'
                            throw e
                        }
                    }
                }
            }
        }

        stage('Run SAST Scan with SonarQube') {
            steps {
                withCredentials([
                    string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
                ]) {
                    script {
                        echo "Running SonarQube scan..."

                        // Run the scan and get task info
                        def scannerOutput = sh(
                            script: '''
                                export PATH=$PATH:/opt/sonar-scanner/bin
                                sonar-scanner \
                                    -Dsonar.projectKey=aspnet-api \
                                    -Dsonar.projectName="AspNet API" \
                                    -Dsonar.projectVersion=1.0 \
                                    -Dsonar.sources=. \
                                    -Dsonar.exclusions=**/bin/**,**/obj/** \
                                    -Dsonar.host.url=http://localhost:9000 \
                                    -Dsonar.login=$SONAR_TOKEN
                            ''',
                            returnStdout: true
                        )

                        // Extract ceTaskId from report-task.txt
                        def ceTaskId = sh(
                            script: "grep 'ceTaskId' .scannerwork/report-task.txt | cut -d'=' -f2",
                            returnStdout: true
                        ).trim()
                        echo "Extracted ceTaskId: ${ceTaskId}"

                        // Wait for background analysis task to complete
                        timeout(time: 2, unit: 'MINUTES') {
                            waitUntil {
                                def status = sh(script: """
                                    curl -s -u ${SONAR_TOKEN}: http://localhost:9000/api/ce/task?id=${ceTaskId} | jq -r .task.status
                                """, returnStdout: true).trim()
                                echo "SonarQube task status: ${status}"
                                return (status == "SUCCESS")
                            }
                        }

                        // Get real vulnerabilities from SonarQube API
                        sh '''
                            curl -s -u $SONAR_TOKEN: "http://localhost:9000/api/issues/search?componentKeys=aspnet-api&types=VULNERABILITY" > sonarqube-report.json
                        '''

                        archiveArtifacts artifacts: 'sonarqube-report.json', fingerprint: true

                        def vulnerabilityCount = sh(script: 'jq ".issues | length" sonarqube-report.json', returnStdout: true).trim()
                        echo "Number of vulnerabilities found: ${vulnerabilityCount}"

                        // Prepare JSON payload for Lambda
                        sh """
                            jq -c --arg build_number "$BUILD_ID" --arg language "$PROJECT_TECHNOLOGY" '{
                                application_language: \$language,
                                build_number: \$build_number,
                                test_type: "SAST",
                                version: "1.114.0",
                                results: .issues
                            }' sonarqube-report.json > lambda-sonarqube-payload.json
                        """

                        archiveArtifacts artifacts: 'lambda-sonarqube-payload.json', fingerprint: true

                        // Invoke Lambda function
                        sh '''
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                            # Ensure the JSON payload is properly formatted
                            jq . lambda-sonarqube-payload.json > /dev/null
                            if [ $? -ne 0 ]; then
                                echo "Invalid JSON payload!"
                                exit 1
                            fi

                            aws lambda invoke \
                                --function-name SaveLogsToCloudWatch \
                                --payload file://lambda-sonarqube-payload.json \
                                --region $AWS_REGION \
                                --cli-binary-format raw-in-base64-out \
                                lambda-sonarqube-response.json

                            if [ $? -ne 0 ]; then
                                echo "Lambda invocation failed!"
                                exit 1
                            fi
                            

                            echo "Lambda function invoked. Response:"
                            cat lambda-sonarqube-response.json
                        '''

                        //Send data to Amazon Cloudwatch
                        sh """
                            BUILD_ID=${env.BUILD_ID}
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                            aws cloudwatch put-metric-data \
                                --namespace $PROJECT_TECHNOLOGY --metric-name "SAST_Vulnerabilities" \
                                --value $vulnerabilityCount \
                                --unit "Count" \
                                --dimensions "Build=$BUILD_ID" \
                                --region $AWS_REGION
                        """
                    }
                }
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

         stage('Run Trivy Docker Image Scan') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                    // Define Docker image variable using environment variables (or manually set them)
                    def DOCKER_IMAGE = "${ECR_REPO}:${IMAGE_TAG}"
                    echo "Running Trivy Scan on Docker image: ${DOCKER_IMAGE}"

                    // Run the Trivy scan on the Docker image and output results in JSON format
                    sh """
                        trivy image --format json --output trivy-report.json ${DOCKER_IMAGE}
                    """

                    // Extract vulnerabilities count from the Trivy report using jq
                    def trivyVulnerabilityCount = sh(script: 'jq "[.Results[].Vulnerabilities | length] | add" trivy-report.json', returnStdout: true).trim()
                    echo "Number of vulnerabilities found in Docker image: ${trivyVulnerabilityCount}"

                    // Archive Trivy report
                    archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true

                     sh """
                        jq -c --arg build_number "$BUILD_ID" --arg language "$PROJECT_TECHNOLOGY" '{
                            application_language: \$language,
                            build_number: \$build_number,
                            test_type: "ImageScan",
                            version: "1.114.0",
                            results: .
                        }' trivy-report.json > lambda-trivy-payload.json
                    """

                        archiveArtifacts artifacts: 'lambda-trivy-payload.json', fingerprint: true

                        // Invoke Lambda function
                        sh '''
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                            # Ensure the JSON payload is properly formatted
                            jq . lambda-trivy-payload.json > /dev/null
                            if [ $? -ne 0 ]; then
                                echo "Invalid JSON payload!"
                                exit 1
                            fi

                            aws lambda invoke \
                                --function-name SaveLogsToCloudWatch \
                                --payload file://lambda-trivy-payload.json \
                                --region $AWS_REGION \
                                --cli-binary-format raw-in-base64-out \
                                lambda-trivy-response.json

                            if [ $? -ne 0 ]; then
                                echo "Lambda invocation failed!"
                                exit 1
                            fi
                            

                            echo "Lambda function invoked. Response:"
                            cat lambda-trivy-response.json
                        '''

                        sh """
                            BUILD_ID=${env.BUILD_ID}
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                            aws cloudwatch put-metric-data \
                                --namespace $PROJECT_TECHNOLOGY --metric-name "ImageScan_Vulnerabilities" \
                                --value $trivyVulnerabilityCount \
                                --unit "Count" \
                                --dimensions "Build=$BUILD_ID" \
                                --region $AWS_REGION
                        """
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
                    try {
                        input message: 'Approve SQL Migrations?', ok: 'Apply Migrations'
                        env.PROCEED_WITH_MIGRATIONS = 'true'
                    } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException e) {
                        echo "SQL Migrations approval aborted. Skipping migration stages."
                        env.PROCEED_WITH_MIGRATIONS = 'false'
                    }
                }
            }
        }

         stage('Fetch RDS Endpoint') {
            when {
                expression { return env.PROCEED_WITH_MIGRATIONS == 'true' }
            }
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
            when {
                expression { return env.PROCEED_WITH_MIGRATIONS == 'true' }
            }
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