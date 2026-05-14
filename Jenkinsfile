pipeline {

  agent {
    label 'gami2023'
  }

  options {

    buildDiscarder(logRotator(
      numToKeepStr: '5',
      artifactNumToKeepStr: '5'
    ))

    timestamps()

  }

  environment {

    REGION = 'ap-south-1'

  }

  stages {

    // CHECKOUT

    stage('Checkout') {

      steps {

        checkout scm

      }
    }

    // VALIDATE REPOSITORY

    stage('Validate Repository') {

      steps {

        sh '''
          echo "Current Workspace:"
          pwd

          echo "Repository Structure:"
          ls -R
        '''
      }
    }

    // DETECT YAML CHANGES

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

          echo "Changed Files:"
          echo "${changed}"

          if (changed) {

            env.BUILD_AMI = "true"

          } else {

            env.BUILD_AMI = "false"

          }

          echo "BUILD_AMI=${env.BUILD_AMI}"
        }
      }
    }

    // VALIDATE AWS ACCESS

    stage('Validate AWS Access') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''
          echo "Validating AWS access..."

          aws sts get-caller-identity
        '''
      }
    }

    // MAKE SCRIPTS EXECUTABLE

    stage('Prepare Scripts') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''
          chmod +x scripts/*.sh
        '''
      }
    }

    // TRIGGER IMAGE BUILDER

    stage('Trigger Image Builder') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''
          echo "Triggering AWS Image Builder..."

          ./scripts/build_ami.sh
        '''
      }
    }

    // WAIT FOR AMI CREATION

    stage('Wait For AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''
          echo "Waiting for AMI build..."

          ./scripts/wait_for_ami.sh
        '''
      }
    }

    // PUBLISH AMI TO SSM

    stage('Publish Latest AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''
          echo "Publishing AMI to SSM..."

          ./scripts/publish_ami.sh
        '''
      }
    }

    // PRINT FINAL AMI

    stage('Print Latest AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''
          echo "Latest AMI:"
          cat output/ami.txt
        '''
      }
    }

  }

  // POST ACTIONS

  post {

    success {

      echo "Golden AMI Pipeline Success"

    }

    failure {

      echo "Golden AMI Pipeline Failed"

    }

    always {

      archiveArtifacts(
        artifacts: 'output/**/*',
        allowEmptyArchive: true
      )

    }
  }
}