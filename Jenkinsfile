pipeline {
  agent {
    kubernetes {
      label  'kaniko-agent'
      yaml '''
        apiVersion: v1
        kind: Pod
        metadata:
          name: kaniko-agent
        spec:
          containers:
          - name: jnlp
          - name: kaniko
            command:
            - /busybox/cat
            image: gcr.io/kaniko-project/executor:debug
            imagePullPolicy: Always
            resources:
              requests:
                cpu: 1
                ephemeral-storage: "1G"
                memory: 4G
              limits:
                cpu: 1
                ephemeral-storage: "2G"
                memory: 16G
            tty: true
            volumeMounts:
            - name: jenkins-cfg
              mountPath: /kaniko/.docker
            - name: workspace
              mountPath: /home/jenkins/workspace
          volumes:
           - name: jenkins-cfg
             projected:
               sources:
               - secret:
                   name: rencibuild-imagepull-secret
                   items:
                   - key: .dockerconfigjson
                     path: config.json
           - name: workspace
             ephemeral:
               volumeClaimTemplate:
                 spec:
                   accessModes: [ "ReadWriteOnce" ]
                   storageClassName: nvme-ephemeral
                   resources:
                     requests:
                       storage: 7G
      '''
    }
  }
  stages {
    stage('Build-Push') {
      environment {
        PATH = "/busybox:/kaniko:$PATH"
        DOCKERHUB_CREDS = credentials("${env.REGISTRY_CREDS_ID_STR}")
        DOCKER_REGISTRY = "${env.DOCKER_REGISTRY}"
      }
      steps {
        container(name: 'kaniko', shell: '/busybox/sh') {
          sh '''
          /kaniko/executor --context . --verbosity debug --destination helxplatform/cloudtop:$BRANCH_NAME
          '''
        }
      }
    }
  }
}
//    steps {
//        container('agent-docker') {
//                  sh '''
//                  docker build -t helxplatform/cloudtop:$BRANCH_NAME .
//                  '''
//              }
//          }
//      }
//      stage('Test') {
//          steps {
//              container('agent-docker') {
//                  sh '''
//                  pytest  -v --image "helxplatform/cloudtop:$BRANCH_NAME" --user howard --passwd test --port 9660
//                  '''
//              }
//          }
//      }
//      stage('Publish') {
//          environment {
//              DOCKERHUB_CREDS = credentials("${env.REGISTRY_CREDS_ID_STR}")
//              DOCKER_REGISTRY = "${env.DOCKER_REGISTRY}"
//          }
//          steps {
//              container('agent-docker') {
//                  sh '''
//                  echo publish
//                  echo $DOCKERHUB_CREDS_PSW | docker login -u $DOCKERHUB_CREDS_USR --password-stdin $DOCKER_REGISTRY
//                  docker push helxplatform/cloudtop:$BRANCH_NAME
//                  '''
//              }
//          }
//          post {
//              success {
//                 build propagate: false, job: "cloudtop-image-analyses/${env.BRANCH_NAME}"
//                 build propagate: false, job: "cloudtop-imagej/${env.BRANCH_NAME}"
//                 build propagate: false, job: "cloudtop-napari/${env.BRANCH_NAME}"
//                 build propagate: false, job: "cloudtop-octave/${env.BRANCH_NAME}"
//                 build propagate: false, job: "cloudtop-verdi/${env.BRANCH_NAME}"
//                 build propagate: false, job: "helxplatform/cloudtop-ohif/${env.BRANCH_NAME}"
//              }
//          }
//      }
