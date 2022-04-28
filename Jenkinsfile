pipeline {
    agent {
        kubernetes {
            cloud 'kubernetes'
            yaml '''
              apiVersion: v1
              kind: Pod
              spec:
                containers:
                - name: agent-docker
                  image: wateim/jenkins-agent:latest
                  command: 
                  - cat
                  tty: true
                  volumeMounts:
                    - name: dockersock
                      mountPath: "/var/run/docker.sock"
                volumes:
                - name: dockersock
                  hostPath:
                    path: /var/run/docker.sock 
            '''
        }
    }
    stages {
        stage('Build') {
            environment {
                DOCKERHUB_CREDS = credentials("${env.REGISTRY_CREDS_ID_STR}")
                DOCKER_REGISTRY = "${env.DOCKER_REGISTRY}"
            }
            steps {
                container('agent-docker') {
                    sh '''
                    docker build -t helxplatform/cloudtop:$BRANCH_NAME .
                    '''
                }
            }
        }
        stage('Test') {
            steps {
                container('agent-docker') {
                    sh '''
                    pytest  -v --image "helxplatform/cloudtop:$BRANCH_NAME" --user howard --passwd test --port 9660
                    '''
                }
            }
        }
        stage('Publish') {
            environment {
                DOCKERHUB_CREDS = credentials("${env.REGISTRY_CREDS_ID_STR}")
                DOCKER_REGISTRY = "${env.DOCKER_REGISTRY}"
            }
            steps {
                container('agent-docker') {
                    sh '''
                    echo publish
                    echo $DOCKERHUB_CREDS_PSW | docker login -u $DOCKERHUB_CREDS_USR --password-stdin $DOCKER_REGISTRY
                    docker push helxplatform/cloudtop:$BRANCH_NAME
                    '''
                }
            }
            post {
                success {
                   build propagate: false, job: "cloudtop-image-analyses/${env.BRANCH_NAME}"
                   build propagate: false, job: "cloudtop-imagej/${env.BRANCH_NAME}"
                   build propagate: false, job: "cloudtop-napari/${env.BRANCH_NAME}"
                   build propagate: false, job: "cloudtop-octave/${env.BRANCH_NAME}"
                   build propagate: false, job: "cloudtop-ohif/${env.BRANCH_NAME}"
                   build propagate: false, job: "cloudtop-verdi/${env.BRANCH_NAME}"
                }
            }
        }
    }
}
