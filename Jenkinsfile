pipeline {
    agent any

    environment {
        serviceName = "devsecops-svc"
        applicationURL = "http://13.246.61.247"
    }

    stages {

        stage('Gitleaks Secret Scan') {
            steps {
                script {
                    sh '''
                    docker run --rm \
                      -v $(pwd):/path \
                      zricethezav/gitleaks:latest detect \
                      --source /path \
                      --report-format json \
                      --report-path /path/gitleaks-report.json \
                      --exit-code 0
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
                    sh 'echo "Gitleaks Report:" && cat gitleaks-report.json || echo "No report generated"'
                }
            }
        }

        stage('Build Artifact') {
            steps {
                sh "mvn clean package -DskipTests=true"
                archive 'target/*.jar'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        mvn sonar:sonar \
                        -Dsonar.projectKey=numeric-application \
                        -Dsonar.projectName="numeric-application" \
                        -Dsonar.host.url=http://13.246.61.247:9000 \
                        -Dsonar.token=sqp_13cd3a6118a277fa67f56a8c461abb6cbd21f990
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    script {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage('Docker Vulnerability Scan') {
            steps {
                parallel(
                    "Trivy Scan": {
                        sh "bash trivy-docker-image-scan.sh"
                    },
                    "OPA Conftest": {
                        sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
                    }
                )
            }
        }

        stage('Docker Build and Push') {
            steps {
                withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
                    sh 'printenv'
                    sh 'sudo docker build -t moketch/numeric-app:"${GIT_COMMIT}" .'
                    sh 'docker push moketch/numeric-app:"${GIT_COMMIT}"'
                }
            }
        }

        stage('Kubernetes Vulnerability Scan') {
            steps {
                parallel(
                    "OPA Scan": {
                        sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
                    },
                    "Trivy Scan": {
                        sh "bash trivy-k8s-scan.sh"
                    }
                )
            }
        }

        stage('Kubernetes Deployment - DEV') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh "sed -i 's#replace#moketch/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                    sh "kubectl apply -f k8s_deployment_service.yaml"
                }
            }
        }

        stage('OWASP ZAP - DAST') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh 'bash zap.sh'
                }
            }
            post {
                always {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report', useWrapperFileDirectly: true])
                }
            }
        }

    }
}
