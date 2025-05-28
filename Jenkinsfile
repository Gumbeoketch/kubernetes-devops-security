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
  -Dsonar.projectKey=numeric-application \
  -Dsonar.projectName='numeric-application' \
  -Dsonar.host.url=http://13.246.61.247:9000 \
  -Dsonar.token=sqp_53d468f94ed28f306fbbf7b75270c86895e21f64""" //this is an auth option for sonarqube
                }
                timeout(time: 2, unit: 'MINUTES') {
                    script {
                        waitForQualityGate abortPipeline: true
        }
    }
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
