pipeline {
    agent any
    parameters {
	    choice(choices: ["mvn clean install", "mvn clean install -DskipTests"], name: "goal", description: "Maven Goal")
	    booleanParam(name: "deploy", defaultValue: false, description: "Deploy the build:")
    }	
    environment {
        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"	    
        NEXUS_URL = "172.31.12.172:8081"
        NEXUS_REPOSITORY = "team-artifacts"
	NEXUS_REPO_ID    = "team-artifacts"
        NEXUS_CREDENTIAL_ID = "nexuslogin"
        ARTVERSION = "${BUILD_ID}-${BUILD_TIMESTAMP}"
    }
	
    stages{
        
        stage('Maven Build'){
            steps {
		echo "Stage: Maven Build"
                sh "${params.goal}"
               // sh 'mvn clean install -DskipTests=true'
            }
        }	
        stage ('Checkstyle Analysis'){
            steps {
		echo "Stage: Checkstyle Analysis"
                sh 'mvn checkstyle:checkstyle'
            }
            post {
                success {
                    echo 'Generated Analysis Result'
                }
            }
        }

        stage('SonarQube Scan') {
          
	  environment {
                    scannerHome = tool 'sonar4.7'
          }

          steps {
            withSonarQubeEnv('sonar') {
	       echo "Stage: SonarQube Scan"
               sh '''${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=team \
                   -Dsonar.projectName=team-repo \
                   -Dsonar.projectVersion=1.0 \
                   -Dsonar.sources=src/ \
                   -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                   -Dsonar.junit.reportsPath=target/surefire-reports/ \
                   -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                   -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml'''
	    }
	  }
	}
        stage("SonarQube Quality Gate"){
	   steps{
	     script{
		     echo "Stage: SonarQube Quality Gate"
		     timeout(time: 5, unit: 'MINUTES') {
                       def qualitygate = waitForQualityGate(webhookSecretId: 'sqreport')
                          if (qualitygate.status != "OK") {
				  catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                     sh "exit 1"
				  }
			  }
		     }
	     }
	   }
	}

        stage("Publish Artifact to Nexus") {
            steps {
                script {
		    echo "Stage: Publish Artifact to Nexus"
                    pom = readMavenPom file: "pom.xml";
                    filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
                    echo "${filesByGlob[0].name} ${filesByGlob[0].path} ${filesByGlob[0].directory} ${filesByGlob[0].length} ${filesByGlob[0].lastModified}"
                    artifactPath = filesByGlob[0].path;
                    artifactExists = fileExists artifactPath;
                    if(artifactExists) {
                        echo "*** File: ${artifactPath}, group: ${pom.groupId}, packaging: ${pom.packaging}, version ${pom.version} ARTVERSION";
                        nexusArtifactUploader(
                            nexusVersion: NEXUS_VERSION,
                            protocol: NEXUS_PROTOCOL,
                            nexusUrl: NEXUS_URL,
                            groupId: pom.groupId,
                            version: ARTVERSION,
                            repository: NEXUS_REPOSITORY,
                            credentialsId: NEXUS_CREDENTIAL_ID,
                            artifacts: [
                                [artifactId: pom.artifactId,
                                classifier: '',
                                file: artifactPath,
                                type: pom.packaging],
                                [artifactId: pom.artifactId,
                                classifier: '',
                                file: "pom.xml",
                                type: "pom"]
                            ]
                        );
                    } 
		    else {
                        error "*** File: ${artifactPath}, could not be found";
                    }
                }
            }
        }
	stage("Fetch from Nexus & Deploy using Ansible"){
                 when {
                   expression {
                       return params.deploy   // will be executed only when expression evaluates to true
                }
            }
		steps{
			echo "Stage: Fetch from Nexus & Deploy using Ansible"
			echo "${params.deploy}"
            }
        }
    }
}
