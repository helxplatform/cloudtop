pipeline {
  agent {
    label 'agent-docker'
  }
  environment {
    PATH = "/busybox:/kaniko:/ko-app/:$PATH"
    REG_OWNER="helxplatform"
    REG_APP="cloudtop"
    COMMIT_HASH="${sh(script:"git rev-parse --short HEAD", returnStdout: true).trim()}"
    IMAGE_NAME="${REG_OWNER}/${REG_APP}"
    TAG1="$BRANCH_NAME"
    TAG2="$COMMIT_HASH"
  }
  stages {
    stage('Build') {
      steps {
        sh '''
        docker build -t $IMAGE_NAME:$TAG1 -t $IMAGE_NAME:$TAG2 .
        '''
      }
    }
    stage('Test') {
      steps {
        sh '''
        python -m pytest  -v --image "$IMAGE_NAME:$BRANCH_NAME" --user howard --passwd test --port 9660
        '''
      }
    }
    stage('Publish') {
      environment {
        DOCKERHUB_CREDS = credentials("${env.REGISTRY_CREDS_ID_STR}")
        DOCKER_REGISTRY = "${env.DOCKER_REGISTRY}"
      }
      steps {
        sh '''
        echo publish
        echo $DOCKERHUB_CREDS_PSW | docker login -u $DOCKERHUB_CREDS_USR --password-stdin $DOCKER_REGISTRY
        docker push $IMAGE_NAME:$TAG1
        docker push $IMAGE_NAME:$TAG2
        '''
      }
  //  post {
  //    success {
  //      build propagate: false, job: "cloudtop-image-analyses/${env.BRANCH_NAME}"
  //      build propagate: false, job: "cloudtop-imagej/${env.BRANCH_NAME}"
  //      build propagate: false, job: "cloudtop-napari/${env.BRANCH_NAME}"
  //      build propagate: false, job: "cloudtop-octave/${env.BRANCH_NAME}"
  //      build propagate: false, job: "cloudtop-verdi/${env.BRANCH_NAME}"
  //      build propagate: false, job: "helxplatform/cloudtop-ohif/${env.BRANCH_NAME}"
  //    }
  //  }
    }
  }
}
