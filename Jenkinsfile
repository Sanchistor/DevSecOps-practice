pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
        ECR_REPO = '266735847393.dkr.ecr.eu-west-1.amazonaws.com/my-app-ecr'
        IMAGE_TAG = "wagtail"
        KUBE_NAMESPACE = 'wagtail'
        HELM_RELEASE_NAME = 'wagtail-release'
        CLUSTER_NAME = 'MYAPP-EKS'
        SAFETY_API_KEY = credentials('safety-api-key')
        TARGET_URL = 'http://a8568afcee77646caadc333c1655a122-1516167197.eu-west-1.elb.amazonaws.com/'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'wagtail-deployment', url: 'https://github.com/Sanchistor/DevSecOps-practice.git'
            }
        }

         stage('Run SAST Scan with Semgrep') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                            # Ensure semgrep is installed if not available
                            if ! command -v semgrep &> /dev/null
                            then
                                echo "semgrep not found, installing..."
                                pip install --user semgrep
                            fi

                            # Ensure ~/.local/bin is in the PATH
                            export PATH=$HOME/.local/bin:$PATH

                            # Verify that semgrep is accessible
                            echo "Checking semgrep version..."
                            semgrep --version

                            # Run semgrep scan
                            semgrep scan --config auto --severity INFO --severity WARNING --severity ERROR --json > semgrep-report.json || true
                            
                        '''
                        archiveArtifacts artifacts: 'semgrep-report.json', fingerprint: true

                        def vulnerabilityCount = sh(script: 'jq ".results | length" semgrep-report.json', returnStdout: true).trim()
                        echo "Number of vulnerabilities found: ${vulnerabilityCount}"

                        // Prepare JSON payload for Lambda function
                        sh '''
                            jq -c --arg build_number "$BUILD_ID" '{
                                application_language: "Wagtail",
                                build_number: $build_number,
                                test_type: "SAST",
                                version: "1.114.0",
                                results: .
                            }' semgrep-report.json > lambda-semgrep-payload.json
                        '''
                        archiveArtifacts artifacts: 'lambda-semgrep-payload.json', fingerprint: true

                        // Invoke Lambda function
                        sh '''
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                            # Ensure the JSON payload is properly formatted
                            jq . lambda-semgrep-payload.json > /dev/null
                            if [ $? -ne 0 ]; then
                                echo "Invalid JSON payload!"
                                exit 1
                            fi

                            aws lambda invoke \
                                --function-name SaveLogsToCloudWatch \
                                --payload file://lambda-semgrep-payload.json \
                                --region $AWS_REGION \
                                --cli-binary-format raw-in-base64-out \
                                lambda-semgrep-response.json

                            if [ $? -ne 0 ]; then
                                echo "Lambda invocation failed!"
                                exit 1
                            fi
                            

                            echo "Lambda function invoked. Response:"
                            cat lambda-semgrep-response.json
                        '''
                        // sh """
                        //     BUILD_ID=${env.BUILD_ID}
                        //     export AWS_REGION=$AWS_REGION
                        //     export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        //     export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        //     aws cloudwatch put-metric-data \
                        //         --namespace "Wagtail_Security" \
                        //         --metric-name "SAST_Vulnerabilities" \
                        //         --value $vulnerabilityCount \
                        //         --unit "Count" \
                        //         --dimensions "Build=$BUILD_ID" \
                        //         --region $AWS_REGION
                        // """
                    }
                }
            }
        }

        stage('Run Dependency Scanning with Safety') {
            steps {
                script {
                     withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        sh '''
                            if ! command -v safety &> /dev/null
                            then
                                echo "Installing Safety..."
                                pip install --user safety
                            fi
                            # Ensure ~/.local/bin is in the PATH
                            export PATH=$HOME/.local/bin:$PATH
                            export SAFETY_API_KEY=${SAFETY_API_KEY}

                            safety scan -r requirements.txt --output json > safety-report.json || true
                        '''
                        archiveArtifacts artifacts: 'safety-report.json', allowEmptyArchive: true
                        

                        // Fetch the number of vulnerabilities from the safety report
                        def vulnerabilityCount = sh(script: 'jq "[.scan_results.projects[].files[].results.dependencies[].specifications[].vulnerabilities.known_vulnerabilities[]] | length" safety-report.json', returnStdout: true).trim()
                        echo "Number of vulnerabilities found: ${vulnerabilityCount}"

                        // Prepare JSON payload for Lambda function
                        sh '''
                            jq -c --arg build_number "$BUILD_ID" '{
                                application_language: "Wagtail",
                                build_number: $build_number,
                                test_type: "DepScan",
                                version: "1.114.0",
                                results: .
                            }' safety-report.json > lambda-safety-payload.json
                        '''
                        archiveArtifacts artifacts: 'lambda-safety-payload.json', fingerprint: true

                        // Invoke Lambda function
                        sh '''
                            export AWS_REGION=$AWS_REGION
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                            # Ensure the JSON payload is properly formatted
                            jq . lambda-safety-payload.json > /dev/null
                            if [ $? -ne 0 ]; then
                                echo "Invalid JSON payload!"
                                exit 1
                            fi

                            aws lambda invoke \
                                --function-name SaveLogsToCloudWatch \
                                --payload file://lambda-safety-payload.json \
                                --region $AWS_REGION \
                                --cli-binary-format raw-in-base64-out \
                                lambda-safety-response.json

                            if [ $? -ne 0 ]; then
                                echo "Lambda invocation failed!"
                                exit 1
                            fi
                            

                            echo "Lambda function invoked. Response:"
                            cat lambda-safety-response.json
                        '''

                        //Send the number of vulnerabilities to CloudWatch

                        // sh """
                        //     BUILD_ID=${env.BUILD_ID}
                        //     export AWS_REGION=$AWS_REGION
                        //     export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        //     export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        //     aws cloudwatch put-metric-data \
                        //         --namespace "Wagtail_Security" \
                        //         --metric-name "DepScan_Vulnerabilities" \
                        //         --value $vulnerabilityCount \
                        //         --unit "Count" \
                        //         --dimensions "Build=$BUILD_ID" \
                        //         --region $AWS_REGION
                        // """
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
                                --values ./django-chart/values.yaml \
                                --recreate-pods
                                
                            echo "Waiting for pod readiness..."
                            while [[ $(kubectl get pods -n $KUBE_NAMESPACE -l app=$HELM_RELEASE_NAME -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
                                echo "Pod not ready yet. Retrying in 10 seconds..."
                                sleep 10
                            done
                            echo "Pod is now ready!"

                        '''
                    }
                }
            }
        }

        stage('Run DAST Scan with OWASP ZAP') {
            steps {
                script {
                    sh '''
                        docker pull ghcr.io/zaproxy/zaproxy:stable

                        echo "Running OWASP ZAP Full Scan on $TARGET_URL..."

                        docker run --rm -v $(pwd):/zap/wrk/:rw owasp/zap2docker-stable zap-full-scan.py \
                            -t $TARGET_URL \
                            -r zap-report.html \
                            -J zap-report.json || true

                        archiveArtifacts artifacts: 'zap-report.json', fingerprint: true
                    '''

                    // Extract vulnerabilities count
                    def vulnerabilityCount = sh(script: 'jq ".site[].alerts | length" zap-report.json', returnStdout: true).trim()
                    echo "Number of vulnerabilities found: ${vulnerabilityCount}"
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
