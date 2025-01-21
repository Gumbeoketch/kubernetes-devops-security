pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //trynna see sam
            }
        }   

    stage('Unit Test') {
            steps {
              sh "mvn test"
            }
        }
       stage('Docker Buuld and Push') {
            steps {
            withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
              sh 'printenv'
              sh 'docker build -t moketch/numeric-app:""$GIT_COMMIT"" .'
              sh 'docker push moketch/numeric-app:""$GIT_COMMIT""'

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
