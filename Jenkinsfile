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
                    chmod 777 $(pwd)
                    docker run --rm \
                      -v $(pwd):/path \
                      zricethezav/gitleaks:latest detect \
                      --source /path \
                      --config /dev/null \
                      --report-format json \
                      --report-path /path/gitleaks-report.json \
                      --exit-code 0

                    python3 -c "
import json, sys
with open('gitleaks-report.json') as f:
    data = json.load(f)
rows = ''
for item in data:
    rows += f'''<tr>
        <td>{item.get('RuleID','')}</td>
        <td>{item.get('Description','')}</td>
        <td>{item.get('File','')}</td>
        <td>{item.get('Line','')}</td>
        <td>{item.get('Commit','')[:8]}</td>
        <td>{item.get('Author','')}</td>
        <td>{item.get('Date','')}</td>
    </tr>'''
html = f'''<!DOCTYPE html>
<html>
<head>
    <title>Gitleaks Secret Scan Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        h1 {{ color: #d9534f; }}
        table {{ border-collapse: collapse; width: 100%; }}
        th {{ background-color: #d9534f; color: white; padding: 10px; text-align: left; }}
        td {{ border: 1px solid #ddd; padding: 8px; word-break: break-all; }}
        tr:nth-child(even) {{ background-color: #f9f9f9; }}
        .summary {{ background: #f2dede; padding: 10px; border-radius: 4px; margin-bottom: 20px; }}
    </style>
</head>
<body>
    <h1>Gitleaks Secret Scan Report</h1>
    <div class='summary'><strong>Total Secrets Found: {len(data)}</strong></div>
    <table>
        <tr>
            <th>Rule ID</th><th>Description</th><th>File</th>
            <th>Line</th><th>Commit</th><th>Author</th><th>Date</th>
        </tr>
        {rows if rows else '<tr><td colspan=7>No secrets found</td></tr>'}
    </table>
</body>
</html>'''
with open('gitleaks-report.html', 'w') as f:
    f.write(html)
print('HTML report generated.')
"
                    '''
                }
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        icon: '',
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'gitleaks-report.html',
                        reportName: 'Gitleaks Secret Scan Report',
                        reportTitles: 'Gitleaks Secret Scan Report',
                        useWrapperFileDirectly: true
                    ])
                    archiveArtifacts artifacts: 'gitleaks-report.json', allowEmptyArchive: true
                }
            }
        }

        stage('Build Artifact') {
            steps {
                sh "mvn clean package -DskipTests=true"
                archive 'target/*.jar'
            }
        }

        stage('Trivy SCA - Dependency Scan') {
            steps {
                sh '''
                    curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl -o trivy-html.tpl
                    trivy fs \
                    --skip-version-check \
                    --format template \
                    --template "@trivy-html.tpl" \
                    --output trivy-dependency-report.html \
                    --severity HIGH,CRITICAL \
                    --exit-code 0 \
                    .
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        icon: '',
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'trivy-dependency-report.html',
                        reportName: 'Trivy Dependency Scan Report',
                        reportTitles: 'Trivy Dependency Scan Report',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }

        stage('Snyk - Open Source Scan') {
            steps {
                sh '''
                    /usr/local/bin/snyk-alpine test \
                    --all-projects \
                    --org=f0205332-5e84-401b-9cd9-0c6292a58be4 \
                    --exclude=trivy || true

                    /usr/local/bin/snyk-alpine monitor \
                    --all-projects \
                    --org=f0205332-5e84-401b-9cd9-0c6292a58be4 \
                    --exclude=trivy || true
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'snyk-report.json', allowEmptyArchive: true
                }
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
                    sh "kubectl rollout status deployment/devsecops --timeout=120s"
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
