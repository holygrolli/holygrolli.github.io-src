pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '15'))
    }
    stages {
        stage ('Init') {
            steps {
                dir("src") {
                    checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'SubmoduleOption', disableSubmodules: false, parentCredentials: false, recursiveSubmodules: false, reference: '', trackingSubmodules: false]], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'GITHUB', url: 'git@github.com:adulescentulus/adulescentulus.github.io-src.git']]])
                }
                dir("target"){
                    checkout([$class: 'GitSCM', branches: [[name: 'refs/heads/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: false], [$class: 'UserIdentity', email: 'andreas.groll@gmail.com', name: 'Andreas Groll'], [$class: 'LocalBranch', localBranch: 'master']], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'GITHUB', name: 'origin', refspec: '+refs/heads/master:refs/remotes/origin/master', url: 'git@github.com:adulescentulus/adulescentulus.github.io.git']]])
                }
            }
        }
        stage ('Hugo Generate') {
            agent {
                docker { 
                    image 'grolland/aws-cli:hugo'
                    alwaysPull true
                    reuseNode true 
                    args '-e TZ=Europe/Berlin'
                }
            }
            steps {
                dir("src") {
                    sh "hugo -d ../target"
                }
            }
        }
        stage ('Deploy Production') {
            when {
                expression { BRANCH_NAME == 'master' }
            }
            steps {
                sshagent(['GITHUB']) {
                    dir("target"){
                        sh """
                            git status
                            git config --global user.email "andreas.groll@gmail.com"
                            git config --global user.name "Andreas Groll"
                            git add .
                            git commit -m 'new content'
                            git push origin master"""
                    }
                }
            }
        }
        stage ('Deploy Staging') {
            when {
                expression { BRANCH_NAME != 'master' }
            }
            environment {
                AWS_DEFAULT_REGION = 'eu-central-1'
                AWS_ACCESS_KEY_ID = credentials('AWS_KEY_HUGOSTAGING_ID')
                AWS_SECRET_ACCESS_KEY = credentials('AWS_KEY_HUGOSTAGING_KEY')
                WEBBUCKET_NAME = "${env.BNC_HUGO_STAGING_NAME}"
            }
            agent {
                docker { 
                    image 'grolland/aws-cli:hugo'
                    alwaysPull true
                    reuseNode true 
                    args '-e TZ=Europe/Berlin'
                }
            }
            steps {
                dir("target"){
                    sh '''aws s3 sync . s3://${WEBBUCKET_NAME} --delete --size-only --metadata-directive REPLACE --cache-control max-age=120'''
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
