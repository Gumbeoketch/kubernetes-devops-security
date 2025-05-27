pipeline {
    agent any

    stages {
        stage('Build Artifact'){
            steps {
                sh "mvn clean package -DskipTests=true"
                archive 'target/*.jar'//so that they can download
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