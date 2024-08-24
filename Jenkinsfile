pipeline {
    agent any

    tools {
        maven 'maven3'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/DevandMlOps/calculadorcita'
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
                    sh '''
                        mvn sonar:sonar \
                          -Dsonar.projectKey=calculadorcita \
                          -Dsonar.projectName='calculadorcita' \
                          -Dsonar.projectVersion=1.0 \
                          -Dsonar.sources=src/main/java/ \
                          -Dsonar.java.binaries=target/classes \
                          -Dsonar.host.url=http://sonarqube:9000
                    '''
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
                    def nexusUrl = 'nexus:8081'
                    def artifactPath = "target/${pom.artifactId}-${pom.version}.jar"
                    
                    nexusArtifactUploader(
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        nexusUrl: nexusUrl,
                        groupId: pom.groupId,
                        version: pom.version,
                        repository: pom.version.endsWith('SNAPSHOT') ? 'maven-snapshots' : 'maven-releases',
                        credentialsId: 'nexus-credentials',
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
}
