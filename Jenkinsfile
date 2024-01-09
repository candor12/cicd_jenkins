pipeline {
    options {
      buildDiscarder(logRotator(numToKeepStr: '3', artifactNumToKeepStr: '3'))
      //skipDefaultCheckout() 
      disableConcurrentBuilds()
  }
    agent any
    parameters {
	    booleanParam(name: "Deploy", defaultValue: false, description: "Deploy the Build")
	    booleanParam(name: "SonarQube", defaultValue: false, description: "ByPass SonarQube Scan")
    }	
    environment {
        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"	    
        NEXUS_URL = "172.31.18.80:8081"
        NEXUS_REPOSITORY = "team-artifacts"
	NEXUS_REPO_ID    = "team-artifacts"
        NEXUS_CREDENTIAL_ID = "nexuslogin"
        ARTVERSION = "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}"
	NEXUS_ARTIFACT = "${env.NEXUS_PROTOCOL}://${env.NEXUS_URL}/repository/${env.NEXUS_REPOSITORY}/com/team/project/tmart/${env.ARTVERSION}/tmart-${env.ARTVERSION}.war"
	ecr_repo = '674583976178.dkr.ecr.us-east-2.amazonaws.com/teamimagerepo'
        ecrCreds = 'awscreds'
	image = ''
    }
	
    stages{
	stage('Maven Build'){
            steps {
                sh 'mvn clean install -DskipTests -Dcheckstyle.skip'
            }}
	    
        stage('JUnit Test') {
          steps {
            script {
              sh 'mvn test'
              junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
            }
          }
        }
	stage ('Checkstyle Analysis'){
            steps {
		script{
		echo "Stage: Checkstyle Analysis"
                sh 'mvn checkstyle:checkstyle'
		catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                sh "exit 1"  }}}
		
            }
	    
        stage('SonarQube Scan') {
	  when {
		  not{
                   expression {
                       return params.SonarQube  }}}
          environment {
                    scannerHome = tool 'sonar4.7'
          }
          steps {
	    script{
              withSonarQubeEnv('sonar') {
	       echo "Stage: SonarQube Scan"
               sh '''${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=jenkins \
                   -Dsonar.projectName=tjenkins \
                   -Dsonar.projectVersion=1.0 \
                   -Dsonar.sources=src/ \
                   -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                   -Dsonar.junit.reportsPath=target/surefire-reports/ \
                   -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                   -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml'''
		    }
		echo "Quality Gate"   
		timeout(time: 5, unit: 'MINUTES') {
                       def qualitygate = waitForQualityGate(webhookSecretId: 'sqwebhook')
                          if (qualitygate.status != "OK") {
				  catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                                     sh "exit 1"  }}}
	  }}}

        stage("Publish Artifact to Nexus") {
            steps {
                script {
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
                    }}}}
	    
	stage('Docker Image Build') {
          steps {
             script {
                image = docker.build(ecr_repo + ":$BUILD_ID", "./") 
	  }}}
	    
        stage('Push Image to ECR'){
           steps {
              script {
                 docker.withRegistry("https://" + ecr_repo, "ecr:us-east-2:" + ecrCreds) {
                   image.push("$BUILD_ID")
                   image.push('latest') }
	      }}
       post {
        always {
            sh 'docker image prune -a -f' } 
       }}	    
	    
	stage("Fetch from Nexus & Deploy using Ansible"){
		agent { label 'agent1' }
                 when {
                   expression {
                       return params.Deploy   
                }}
		steps{
			dir('ansible'){
			echo "${params.Deploy}"
			sh '''
                        ansible-playbook deployment.yml -e NEXUS_ARTIFACT=${NEXUS_ARTIFACT}  > live_log && tail -2 live_log
			ls -l
                        pwd
			'''
            }}}
        stage('Deploy to EKS'){
		 agent { label 'agent1' }
                 when {
                   expression {
                       return params.Deploy   
                }}
            steps {
                 sh '''
		 kubectl apply -f eks1.yml
		 kubectl get deployments  
                 sleep 10
                 kubectl get svc
                 '''   }
         post {
          always { cleanWs() }
        }
	}
}
	post {
          always { cleanWs() }
        }
}
