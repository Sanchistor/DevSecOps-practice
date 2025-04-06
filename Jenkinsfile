def IMAGE_TAG = ''
def KUBE_NAMESPACE = ''
def HELM_RELEASE_NAME = ''
def PROJECT_TECHNOLOGY = ''

// ─────────────────────────────
// Shared Function - Artifact Processor
// ─────────────────────────────
def processSecurityArtifact(Map args) {
    def file = args.file
    def testType = args.testType
    def countCommand = args.countCommand
    def outputPayload = "lambda-${testType.toLowerCase()}-payload.json"
    def outputResponse = "lambda-${testType.toLowerCase()}-response.json"
    def projectTechnology = args.projectTechnology

    def vulnCount = sh(script: countCommand, returnStdout: true).trim()
    echo "[$testType] Vulnerabilities found: $vulnCount"

    archiveArtifacts artifacts: file, fingerprint: true

    sh """
        jq -c --arg build_number "$BUILD_ID" --arg language "$projectTechnology" '{
            application_language: \$language,
            build_number: \$build_number,
            test_type: "$testType",
            version: "1.0.0",
            results: .
        }' $file > $outputPayload
    """

    archiveArtifacts artifacts: outputPayload, fingerprint: true

    sh """
        export AWS_REGION=$AWS_REGION
        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

        jq . $outputPayload > /dev/null || (echo "Invalid JSON payload!" && exit 1)

        aws lambda invoke \
            --function-name SaveLogsToCloudWatch \
            --payload file://$outputPayload \
            --region $AWS_REGION \
            --cli-binary-format raw-in-base64-out \
            $outputResponse

        cat $outputResponse

        aws cloudwatch put-metric-data \
            --namespace "$projectTechnology" \
            --metric-name "${testType}_Vulnerabilities" \
            --value $vulnCount \
            --unit "Count" \
            --dimensions "Build=$BUILD_ID" \
            --region $AWS_REGION
    """
}

pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-west-1'
        ECR_REPO = '266735847393.dkr.ecr.eu-west-1.amazonaws.com/my-app-ecr'
        CLUSTER_NAME = 'MYAPP-EKS'
        PROJECT_LANGUAGE = ''

        //DATABASE CONFIG
        MIGRATIONS_DIR = "Migrations" 
        POSTGRES_DB = credentials('database_name-asp')
        POSTGRES_USER = credentials('database-user')
        POSTGRES_PASSWORD = credentials('postgres-password')

        //Security tools creedentials
        SNYK_TOKEN = credentials('SNYK_TOKEN')
        SAFETY_API_KEY = credentials('safety-api-key')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'asp-deployment', url: 'https://github.com/Sanchistor/DevSecOps-practice.git'
            }
        }

        stage('Detect Project Language') {
            steps {
                script {
                    def csprojFiles = ''
                    PROJECT_LANGUAGE = 'Unknown'

                    if (fileExists('requirements.txt')) {
                        PROJECT_LANGUAGE = 'wagtail'
                        IMAGE_TAG = 'wagtail'
                        HELM_RELEASE_NAME = 'wagtail-release'
                        KUBE_NAMESPACE = 'wagtail'
                        PROJECT_TECHNOLOGY = 'Wagtail'
                    } else {
                        csprojFiles = sh(script: 'find . -name "*.csproj" | head -n 1', returnStdout: true).trim()
                        if (csprojFiles) {
                            PROJECT_LANGUAGE = 'aspnet'
                            IMAGE_TAG = 'asp'
                            HELM_RELEASE_NAME = 'asp-release'
                            KUBE_NAMESPACE = 'aspnet'
                            PROJECT_TECHNOLOGY = 'AspNet'
                        }
                    }

                    if (PROJECT_LANGUAGE == 'Unknown') {
                        error "Could not detect project language. Please check your repo structure."
                    }

                    echo "Detected Project Language: ${PROJECT_LANGUAGE}"
                }
            }
        }


        stage('Run Dependency Scanning Test') {
            steps {
                withCredentials([
                    string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
                ]) {
                    script {
                        if (PROJECT_LANGUAGE == 'wagtail') {
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

                        } else if (PROJECT_LANGUAGE == 'aspnet') {
                            // Running snyk test and capturing output for debugging
                            sh """
                                snyk auth $SNYK_TOKEN
                                snyk test --all-projects --json --debug > snyk-report.json || true
                            """
                            // Archive the Snyk report for further inspection
                            archiveArtifacts artifacts: 'snyk-report.json', fingerprint: true

                            processSecurityArtifact(
                                file: 'snyk-report.json',
                                testType: 'DepScan',
                                countCommand: 'jq ".vulnerabilities | length" snyk-report.json',
                                projectTechnology: PROJECT_TECHNOLOGY
                            )

                        } else if (PROJECT_LANGUAGE == 'nodejs') {
                            echo "NodeJs Dependecy scanning stage here ..."
                        }

                        }
                    }
                }
            }
        

        stage('Run SAST Scan') {
            steps {
                withCredentials([
                    string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN'),
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
                ]) {
                    script {
                        if (PROJECT_LANGUAGE == 'wagtail') {
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

                        } else if (PROJECT_LANGUAGE == 'aspnet') {
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

                            processSecurityArtifact(
                                file: 'sonarqube-report.json',
                                testType: 'SAST',
                                countCommand: 'jq ".issues | length" sonarqube-report.json',
                                projectTechnology: PROJECT_TECHNOLOGY
                            )

                        } else if (PROJECT_LANGUAGE == 'nodejs') {
                            echo "NodeJs SAST scanning stage here ..."
                        }
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
            environment {
                IMAGE_TAG = "${IMAGE_TAG}"
            }
            steps {
                script {
                    sh '''
                        docker build -t $ECR_REPO:$IMAGE_TAG .
                        docker push $ECR_REPO:$IMAGE_TAG
                    '''
                }
            }
        }

         stage('Run Docker Image Scan') {
            environment {
                IMAGE_TAG = "${IMAGE_TAG}"
            }
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
                        archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true

                        processSecurityArtifact(
                            file: 'trivy-report.json',
                            testType: 'ImageScan',
                            countCommand: 'jq "[.Results[].Vulnerabilities | length] | add" trivy-report.json',
                            projectTechnology: PROJECT_TECHNOLOGY
                        )
                    }
                }   
            }
        }

        stage('Deploy to EKS using Helm') {
            environment {
                HELM_RELEASE_NAME = "${HELM_RELEASE_NAME}"
                KUBE_NAMESPACE = "${KUBE_NAMESPACE}"
            }
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
                        // Set the current build description to track approval status
                        currentBuild.description = 'Migrations Approved'
                    } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException e) {
                        echo "SQL Migrations approval aborted. Skipping migration stages."
                        currentBuild.description = 'Migrations Not Approved'
                    }
                }
            }
        }


         stage('Fetch RDS Endpoint') {
            when {
                expression { return currentBuild.description == 'Migrations Approved' }
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
                expression { return currentBuild.description == 'Migrations Approved' }
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