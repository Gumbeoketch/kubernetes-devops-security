pipeline {
    agent any

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
    
   //stage('Docker Vulnerability Scan') {
       // steps {
         //   sh "mvn dependency-check:check"
        // }
        //post {
          //  always {
            //    dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
       //     }
      //  }
   // }
    
    stage ('Docker Vulnerability Scan){
        steps {
            sh "bash trivy-docker-image-scan.sh"
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
