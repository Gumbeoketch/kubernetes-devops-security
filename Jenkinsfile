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
    
    }
}
