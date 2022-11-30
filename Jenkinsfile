library 'pipeline-utils@master'

CCV = ""

pipeline {
  agent {
    kubernetes {
        label 'kaniko-build-agent'
        yaml """
kind: Pod
metadata:
  name: kaniko
spec:
  containers:
    - name: jnlp
      workingDir: /home/jenkins/agent
    - name: kaniko
      workingDir: /home/jenkins/agent
      image: gcr.io/kaniko-project/executor:latest
      imagePullPolicy: IfNotPresent
      command:
      - /busybox/cat
      tty: true
      volumeMounts:
      - name: jenkins-docker-cfg
        mountPath: /kaniko/.docker
  volumes:
  - name: jenkins-docker-cfg
    secret:
      secretName: rencibuild-imagepull-secret
      items:
      - key: .dockerconfigjson
        path: config.json
"""
        }
    }
    environment {
        PATH = "/busybox:/kaniko:/ko-app/:$PATH"
        DOCKERHUB_CREDS = credentials("${env.CONTAINERS_REGISTRY_CREDS_ID_STR}")
        REGISTRY = "${env.REGISTRY}"
        REG_OWNER="helxplatform"
        REPO_NAME="cloudtop"
        COMMIT_HASH="${sh(script:"git rev-parse --short HEAD", returnStdout: true).trim()}"
        IMAGE_NAME="${REGISTRY}/${REG_OWNER}/${REPO_NAME}"
    }
    stages {
        stage('Build') {
            steps {
                script {
                    container(name: 'go', shell: '/bin/bash') {
                        if (BRANCH_NAME.equals("master")) {
                            CCV = go.ccv()
                        }
                    }
                    container(name: 'kaniko', shell: '/busybox/sh') {
                        def tagsToPush = ["$IMAGE_NAME:$BRANCH_NAME", "$IMAGE_NAME:$COMMIT_HASH"]
                        if (CCV != null && !CCV.trim().isEmpty() && BRANCH_NAME.equals("master")) {
                            tagsToPush.add("$IMAGE_NAME:$CCV")
                            tagsToPush.add("$IMAGE_NAME:latest")
                        } else {
                            def now = new Date()
                            def currTimestamp = now.format("yyyy-MM-dd'T'HH.mm'Z'", TimeZone.getTimeZone('UTC'))
                            tagsToPush.add("$IMAGE_NAME:$currTimestamp")
                        }
                        kaniko.buildAndPush("./Dockerfile", tagsToPush)
                    }
                }
            }
        }
    }
}

// pipeline {
//   agent {
//     kubernetes {
//         label 'kaniko-build-agent'
//         yaml """
// kind: Pod
// metadata:
//   name: kaniko
// spec:
//   containers:
//   - name: jnlp
//     workingDir: /home/jenkins/agent/
//   - name: kaniko
//     workingDir: /home/jenkins/agent/
//     image: gcr.io/kaniko-project/executor@sha256:10841c0e915d4436fc091531a38e6f0d790422f6e87119e20c347d93c3a14172
//     imagePullPolicy: IfNotPresent
//     resources:
//       requests:
//         cpu: "512m"
//         memory: "1024Mi"
//         ephemeral-storage: "2816Mi"
//       limits:
//         cpu: "1024m"
//         memory: "2048Mi"
//         ephemeral-storage: "3Gi"
//     - command:
//     tty: true
//     volumeMounts:
//     // - name: kaniko
//     //   mountPath: /kaniko-data
//     - name: jenkins-docker-cfg
//       mountPath: /kaniko/.docker
//     - name: kaniko-cache
//       mountPath: 
//   volumes:
//   - name: jenkins-docker-cfg
//     projected:
//       sources:
//       - secret:
//           name: rencibuild-imagepull-secret
//           items:
//             - key: .dockerconfigjson
//               path: config.json
//   - name: kaniko-cache
//     emptyDir:
//       sizeLimit: 3Gi
//   // - name: kaniko
//   //   persistentVolumeClaim:
//   //   claimName: kaniko-pvc
// """
//         }
//     }
//   environment {
//     PATH = "/busybox:/kaniko:/ko-app/:$PATH"
//     REG_OWNER="helxplatform"
//     REG_APP="cloudtop"
//     COMMIT_HASH="${sh(script:"git rev-parse --short HEAD", returnStdout: true).trim()}"
//     IMAGE_NAME="${REG_OWNER}/${REG_APP}"
//     TAG1="$BRANCH_NAME"
//     TAG2="$COMMIT_HASH"
//     REGISTRY=""
//   }
//   stages {
//     stage('Build Image and Push to Registry') {
//           steps {
//             container(name: 'kaniko', shell: '/busybox/sh') {
//                 sh '''#!/busybox/sh
//                   /kaniko/executor \
//                     --dockerfile `pwd`/Dockerfile \
//                     --context `pwd`/ \
//                     --verbosity debug \
//                     --kaniko-dir /kaniko \
//                     --destination $REGISTRY$IMAGE_NAME:$TAG1 \
//                     --destination $REGISTRY$IMAGE_NAME:$TAG2
//                 '''
//             }
//           }
//         }

//     stage('Build') {
//       steps {
//         sh '''
//         docker build -t $IMAGE_NAME:$TAG1 -t $IMAGE_NAME:$TAG2 .
//         '''
//       }
//     }
//     stage('Test') {
//       steps {
//         sh '''
//         python -m pytest  -v --image "$IMAGE_NAME:$BRANCH_NAME" --user howard --passwd test --port 9660
//         '''
//       }
//     }
//     stage('Publish') {
//       environment {
//         DOCKERHUB_CREDS = credentials("${env.REGISTRY_CREDS_ID_STR}")
//         DOCKER_REGISTRY = "${env.DOCKER_REGISTRY}"
//       }
//       steps {
//         sh '''
//         echo publish
//         echo $DOCKERHUB_CREDS_PSW | docker login -u $DOCKERHUB_CREDS_USR --password-stdin $DOCKER_REGISTRY
//         docker push $IMAGE_NAME:$TAG1
//         docker push $IMAGE_NAME:$TAG2
//         '''
//       }


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

    // }
//   }
// }
