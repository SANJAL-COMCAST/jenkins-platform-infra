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

    // =========================================================
    // CHECKOUT
    // =========================================================

    stage('Checkout') {

      steps {

        checkout scm

      }
    }

    // =========================================================
    // VALIDATE REPOSITORY
    // =========================================================

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

    // =========================================================
    // DETECT YAML CHANGES
    // =========================================================

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

    // =========================================================
    // VALIDATE AWS ACCESS
    // =========================================================

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

    // =========================================================
    // PREPARE SCRIPTS
    // =========================================================

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

    // =========================================================
    // TRIGGER IMAGE BUILDER
    // =========================================================

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

    // =========================================================
    // WAIT FOR AMI
    // =========================================================

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

    // =========================================================
    // PUBLISH TO SSM
    // =========================================================

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

    // =========================================================
    // PRINT AMI
    // =========================================================

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

    // =========================================================
    // UPDATE JENKINS CLOUD
    // =========================================================

        stage('Update Jenkins Cloud AMI') {

      when {
        expression { env.BUILD_AMI == "true" }
      }

      agent {
        label 'built-in'
      }

      steps {

        // unstash 'ami-output'

        script {

        //   env.LATEST_AMI = sh(
        //     script: 'cat output/ami.txt',
        //     returnStdout: true
        //   ).trim()
        env.LATEST_AMI = "ami-0db8a006b98252fd9"

          echo "Latest AMI: ${env.LATEST_AMI}"

        }

        writeFile(
          file: 'latest_ami.txt',
          text: env.LATEST_AMI
        )

        withCredentials([usernamePassword(
          credentialsId: 'jenkins-api-creds',
          usernameVariable: 'JENKINS_USER',
          passwordVariable: 'JENKINS_TOKEN'
        )]) {

          sh '''

            export LATEST_AMI=$(cat latest_ami.txt)

            curl -X POST \
  --user "$JENKINS_USER:$JENKINS_TOKEN" \
  --data-urlencode "LATEST_AMI=$LATEST_AMI" \
  --data-urlencode "script=$(cat scripts/update_cloud.groovy)" \
  http://localhost:8080/scriptText

          '''
        }
      }
    }
  }

  // =========================================================
  // POST
  // =========================================================

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
