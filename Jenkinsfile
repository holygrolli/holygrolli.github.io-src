pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '15'))
    }
    triggers { upstream(upstreamProjects: "blog-cron-trigger-${BRANCH_NAME}", threshold: hudson.model.Result.SUCCESS) }
    stages {
        stage ('Init') {
            steps {
                dir("src") {
                    checkout([$class: 'GitSCM', branches: [[name: '*/${BRANCH_NAME}']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'SubmoduleOption', disableSubmodules: false, parentCredentials: false, recursiveSubmodules: false, reference: '', trackingSubmodules: false]], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'GITHUB', url: 'git@github.com:adulescentulus/adulescentulus.github.io-src.git']]])
                }
                dir("target"){
                    checkout([$class: 'GitSCM', branches: [[name: 'refs/heads/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'CloneOption', depth: 0, noTags: false, reference: '', shallow: false], [$class: 'UserIdentity', email: 'andreas.groll@gmail.com', name: 'Andreas Groll'], [$class: 'LocalBranch', localBranch: 'master']], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'GITHUB', name: 'origin', refspec: '+refs/heads/master:refs/remotes/origin/master', url: 'git@github.com:adulescentulus/adulescentulus.github.io.git']]])
                }
            }
        }
        stage ('Hugo Generate Master') {
            when {
                expression { BRANCH_NAME == 'master' }
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
                dir("src") {
                    sh "hugo --cleanDestinationDir -d ../target"
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
                        sh """#!/bin/bash
                            git status
                            echo checkpoint 1
                            git status --short
                            git config --global user.email "andreas.groll@gmail.com"
                            git config --global user.name "Andreas Groll"
                            echo checkpoint 2
                            [[ \$(git status --short | wc -c) -ne 0 ]] && \
                            echo changes found && \
                            git add . && \
                            git commit -m 'new content' && \
                            git push origin master
                            """
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
                BASEURL = "${env.BNC_HUGO_STAGING_URL}"
            }
            agent {
                docker { 
                    image 'grolland/aws-cli:hugo'
                    alwaysPull true
                    reuseNode true 
                    args "-e TZ=Europe/Berlin -v ${env.BNC_HUGO_STAGING_PATH}:/mnt/target"
                }
            }
            steps {
                dir("src") {
                    sh "HUGO_BASEURL=${BASEURL} hugo --environment development --cleanDestinationDir -d ../target"
                }
                dir("target"){
                    sh '''rm -rf /mnt/target/* | echo "nothing to delete"
                    cp -R . /mnt/target'''
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
