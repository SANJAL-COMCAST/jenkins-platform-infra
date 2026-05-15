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

    // Checkout

    stage('Checkout') {

      steps {

        checkout scm

      }
    }

    // Validate Repository

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

    // Detect Infra Changes

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

    // Validate AWS Access

    stage('Validate AWS Access') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''
          aws sts get-caller-identity
        '''
      }
    }

    // Prepare Scripts

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

    // Trigger Image Builder

    stage('Trigger Image Builder') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''

          echo "Triggering Image Builder..."

          ./scripts/build_ami.sh

        '''
      }
    }

    // Wait For AMI

    stage('Wait For AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''

          echo "Waiting for AMI..."

          ./scripts/wait_for_ami.sh

        '''
      }
    }

    // Publish Latest AMI

    stage('Publish Latest AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''

          echo "Publishing latest AMI..."

          ./scripts/publish_ami.sh

        '''
      }
    }

    // Print Latest AMI

    stage('Print Latest AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      steps {

        sh '''
          cat output/ami.txt
        '''

        stash(
          name: 'ami-output',
          includes: 'output/ami.txt'
        )
      }
    }

    // Update Jenkins Cloud AMI

    stage('Update Jenkins Cloud AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      agent {
        label 'built-in'
      }

      steps {

        unstash 'ami-output'

        script {

          env.LATEST_AMI = sh(
            script: 'cat output/ami.txt',
            returnStdout: true
          ).trim()

          echo "Latest AMI: ${env.LATEST_AMI}"
        }

        withCredentials([usernamePassword(
          credentialsId: 'jenkins-api-creds',
          usernameVariable: 'JENKINS_USER',
          passwordVariable: 'JENKINS_TOKEN'
        )]) {

          sh '''

            SCRIPT_CONTENT=$(cat scripts/update_cloud.groovy)

            SCRIPT_CONTENT="def latestAmi='${LATEST_AMI}'\n${SCRIPT_CONTENT}"

            curl -X POST \
              --user "$JENKINS_USER:$JENKINS_TOKEN" \
              --data-urlencode "script=${SCRIPT_CONTENT}" \
              http://localhost:8080/scriptText

          '''
        }
      }
    }
  }

  // Post Actions

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