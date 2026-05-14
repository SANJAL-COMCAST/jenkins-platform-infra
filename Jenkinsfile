pipeline {

  agent {
    label 'gami2023'
  }

  options {

    buildDiscarder(logRotator(
      numToKeepStr: '5'
    ))

  }

  environment {

    REGION = 'ap-south-1'

  }

  stages {

    stage('Checkout') {

      steps {
        checkout scm
      }
    }

    stage('Detect Infra Changes') {

      steps {

        script {

          def changed = sh(
            script: '''
              git diff --name-only HEAD~1 HEAD |
              grep "^components/.*\\.yaml$\\|^components/.*\\.yml$" || true
            ''',
            returnStdout: true
          ).trim()

          if (changed) {
            env.BUILD_AMI = "true"
          } else {
            env.BUILD_AMI = "false"
          }

          echo "BUILD_AMI=${env.BUILD_AMI}"
        }
      }
    }

    stage('Validate AWS Access') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh 'aws sts get-caller-identity'
      }
    }

    stage('Trigger Image Builder') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh 'chmod +x scripts/*.sh'

        sh './scripts/build_ami.sh'
      }
    }

    stage('Wait For AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh './scripts/wait_for_ami.sh'
      }
    }

    stage('Publish Latest AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh './scripts/publish_ami.sh'
      }
    }

    stage('Print AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh 'cat output/ami.txt'
      }
    }
  }

  post {

    success {

      echo "Golden AMI Pipeline Success"
    }

    failure {

      echo "Golden AMI Pipeline Failed"
    }
  }
}