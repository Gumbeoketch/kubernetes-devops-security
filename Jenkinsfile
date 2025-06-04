pipeline {
    agent any

    // environment {
     //  deploymentName = "devsecops"
      //  containerName = "devsecops-container"
       // serviceName = "devsecops-svc"
       // imageName = "moketch/numeric-app:${GIT_COMMIT}#g"
        // applicationURL = "http://13.246.61.247"
    // }

    stages {
        stage('Build Artifact'){
            steps {
                sh "mvn clean package -DskipTests=true"
                archive 'target/*.jar'//so that they can download
            }
        }

    stage('Sonarqube SAST') {
            steps {
                withSonarQubeEnv('SonarQube') { //this is an auth option for sonarqube
            sh """mvn clean verify sonar:sonar \
  -Dsonar.projectKey=numeric-application_2 \
  -Dsonar.projectName='numeric-application_2' \
  -Dsonar.host.url=http://13.246.61.247:9000 \
  -Dsonar.token=sqp_340a3b1c202e1d14660242f4c2ce30208662de1d""" //this is an auth option for sonarqube #2
                }
                timeout(time: 2, unit: 'MINUTES') {
                    script {
                        waitForQualityGate abortPipeline: true
        }
    }
            }
    }
    
   //stage('Docker Vulnerability Dependency Scan') {
       // steps {
         //   sh "mvn dependency-check:check"
        // }
        //post {
          //  always {
            //    dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
       //     }
      //  }
   // }
    
    stage('Docker Vulnerability Scan') {
        steps {
            parallel(
                "Trivy Scan":{
                    sh "bash trivy-docker-image-scan.sh"
                },
                "OPA Conftest":{
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


    stage('Kubernetes Vulnerability Scan') {  //scan for images pulled from docker hub before k8s cluster deployment
        steps {
            parallel(
                "OPA Scan": {
                    sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
        },
                "Kubesec Scan": {
                    sh "bash kubesec-scan.sh"
        },
                "Trivy Scan":{
                    sh "bash trivy-k8s-scan.sh"
                }
            )
        }
}

   // stage('Kubernetes Deployment - DEV') {
     //       steps {
       //         parallel (
         //       "Deployment": {
           //         withKubeConfig([credentialsId: 'kubeconfig']) {
            //            sh "kubectl apply -f k8s_deployment_service.yaml"
            //    }
           // },

             //   "Rollout Status": {
               //     withKubeConfig([credentialsId: 'kubeconfig']) {
                //       sh "bash k8s-deployment-rollout-status.sh"
                //  }
            //    }
        //    )
     //   }

   // }

// }
// }

            stage('Kubernetes Deployment - DEV') {
                steps {
                    withKubeConfig([credentialsId: 'kubeconfig']) {
                        sh "sed -i 's#replace#moketch/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                        sh "kubectl apply -f k8s_deployment_service.yaml"
                                }
                            }
                        }
                    }
                }
      
            stage('OWASP ZAP - DAST') {
                steps {
                    withKubeConfig([credentialsId: 'kubeconfig']) {
                        sh 'bash zap.sh'
                         }
                     }
                }