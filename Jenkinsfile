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
    
    stage('Sonarqube SAST') {
            steps {
              withSonarQubeEnv('SonarQube') {
              sh "mvn clean verify sonar:sonar \
  -Dsonar.projectKey=numeric-application \
  -Dsonar.projectName='numeric-application' \
  -Dsonar.host.url=http://13.247.56.111:9000 \
  -Dsonar.token=sqp_cff98574ffb36113e6c5e72ea46dc7707b9a3209"

            }
      timeout(time: 2, unit: 'MINUTES') {
        script {
          waitForQualityGate abortPipeline: true
        }
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
