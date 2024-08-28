pipeline {
    agent any

    tools {
        maven 'maven3'
    }

    environment {
        SLACK_CHANNEL = '#appdevops'
        SONARQUBE_URL = 'http://sonarqube:9000'
        NEXUS_URL = 'nexus:8081'
        NEXUS_CREDENTIALS_ID = 'nexus-credentials'
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    git branch: 'main', url: 'https://github.com/DevandMlOps/calculadorcita'
                    env.GIT_AUTHOR_NAME = sh(
                        script: "git log -1 --pretty=format:'%an'",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh """
                        mvn sonar:sonar \
                          -Dsonar.projectKey=calculadorcita \
                          -Dsonar.projectName='calculadorcita' \
                          -Dsonar.projectVersion=1.0 \
                          -Dsonar.sources=src/main/java/ \
                          -Dsonar.java.binaries=target/classes \
                          -Dsonar.host.url=${env.SONARQUBE_URL}
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Upload Artifact to Nexus') {
            steps {
                script {
                    def pom = readMavenPom file: 'pom.xml'
                    def artifactPath = "target/${pom.artifactId}-${pom.version}.jar"

                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: env.NEXUS_URL,
                        groupId: pom.groupId,
                        version: pom.version,
                        repository: pom.version.endsWith('SNAPSHOT') ? 'maven-snapshots' : 'maven-releases',
                        credentialsId: env.NEXUS_CREDENTIALS_ID,
                        artifacts: [
                            [artifactId: pom.artifactId,
                             classifier: '',
                             file: artifactPath,
                             type: 'jar']
                        ]
                    )
                }
            }
        }
    }

post {
        always {
            script {
                def COLOR_MAP = [
                    'SUCCESS': 'good',
                    'FAILURE': 'danger',
                    'UNSTABLE': 'warning',
                    'ABORTED': 'warning'
                ]
                
                def buildStatus = currentBuild.currentResult
                def errorMessage = ""
                
                if (buildStatus == 'FAILURE') {
                    errorMessage = currentBuild.rawBuild.getLog(1000).join('\n')
                    if (errorMessage.length() > 1000) {
                        errorMessage = errorMessage.take(1000) + "... [mensaje truncado]"
                    }
                }
                
                echo 'Enviando notificación a Slack'
                slackSend(
                    channel: env.SLACK_CHANNEL,
                    color: COLOR_MAP[buildStatus],
                    message: """*${buildStatus}: Job ${env.JOB_NAME} build ${env.BUILD_NUMBER}*
                        Branch: ${env.GIT_BRANCH}
                        Commit: ${env.GIT_COMMIT}
                        Author: ${env.GIT_AUTHOR_NAME}
                        More Info at: ${env.BUILD_URL}
                        ${buildStatus == 'FAILURE' ? "\nError Details:\n```${errorMessage}```" : ''}
                    """.stripIndent()
                )
            }
        }
    }
}
