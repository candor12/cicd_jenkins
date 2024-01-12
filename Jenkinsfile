pipeline {
	options {
		buildDiscarder(logRotator(numToKeepStr: '5'))
                skipDefaultCheckout() 
                disableConcurrentBuilds()
	}
	agent any
	parameters {
		booleanParam(name: "EksDeploy", defaultValue: false, description: "Deploy the Build to EKS")
		booleanParam(name: "AnsibleDeploy", defaultValue: false, description: "Deploy the Build to Target Server using Ansible")
		booleanParam(name: "SonarQube", defaultValue: false, description: "By-Pass SonarQube Scan")
	}	
	environment {
		NEXUS_VERSION = "nexus3"
                NEXUS_PROTOCOL = "http"	    
                NEXUS_URL = "172.31.17.3:8081"
                NEXUS_REPOSITORY = "team-artifacts"
	        NEXUS_REPO_ID    = "team-artifacts"
                NEXUS_CREDENTIAL_ID = "nexuslogin"
                ARTVERSION = "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}"
	        NEXUS_ARTIFACT = "${env.NEXUS_PROTOCOL}://${env.NEXUS_URL}/repository/${env.NEXUS_REPOSITORY}/com/team/project/tmart/${env.ARTVERSION}/tmart-${env.ARTVERSION}.war"
	        scannerHome = tool 'sonar4.7'
	        ecr_repo = '674583976178.dkr.ecr.us-east-2.amazonaws.com/teamimagerepo'
                ecrCreds = 'awscreds'
	        dockerImage = "${env.ecr_repo}:${env.BUILD_ID}"
	}
	stages{
		stage('SCM Checkout'){
			steps{
				git branch: 'master', url: 'https://github.com/azka-begh/CICD-with-Jenkins.git'
		}}
		stage('Maven Build'){
			steps {
				sh 'mvn clean install -DskipTests'
			}}
		stage('JUnit Test') {
			steps {
				script {
					sh 'mvn test'
					junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
				}}}
		stage ('Checkstyle Analysis') {
			steps {
				script{
					sh 'mvn checkstyle:checkstyle'
				}}}
		stage('SonarQube Scan') {
			when { not{ expression { return params.SonarQube  }}}
			tools { jdk "jdk-11" }
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
					echo "Waiting for Quality Gate"
					timeout(time: 5, unit: 'MINUTES') {
						def qualitygate = waitForQualityGate(webhookSecretId: 'sqwebhook')
						if (qualitygate.status != "OK") { catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') { sh "exit 1"  } }}
				}}} 
		stage('Publish Artifact to Nexus') {
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
							repository: NEXUS_REPOSITORY,credentialsId: NEXUS_CREDENTIAL_ID,
							artifacts: [
								[artifactId: pom.artifactId,
								 classifier: '',
								 file: artifactPath,
                                                                 type: pom.packaging],
                                                                 [artifactId: pom.artifactId,
                                                                  classifier: '',
                                                                  file: "pom.xml",
                                                                  type: "pom"]]
						);
					}
					else {
						error "*** File: ${artifactPath}, could not be found";
					}}}} 
		stage('Docker Image Build') {
			agent { label 'agent1' }
			steps {
				script {
					git branch: 'master', url: 'https://github.com/azka-begh/CICD-with-Jenkins.git'
					image = docker.build(ecr_repo + ":$BUILD_ID", "./") 
				}}}
		stage ('Trivy Scan') {
			agent { label 'agent1' }
			steps{
				script {
					 sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl > ./html.tpl'
				         sh 'trivy image --skip-db-update --skip-java-db-update --cache-dir ~/trivy/ --format template --template \"@./html.tpl\" -o trivy.html --severity MEDIUM,HIGH,CRITICAL ${dockerImage}' 
				}}
			post { always { archiveArtifacts artifacts: "trivy.html", fingerprint: true
				                     publishHTML target : [
							     allowMissing: true,
							     alwaysLinkToLastBuild: true,
							     keepAll: true,
							     reportDir: './',
							     reportFiles: 'trivy.html',
							     reportName: 'Trivy Scan',
							     reportTitles: 'Trivy Scan']
				      }}
		}		
		stage('Push Image to ECR') {
			agent { label 'agent1' }
			steps {
				script {
					docker.withRegistry("https://" + ecr_repo, "ecr:us-east-2:" + ecrCreds) {
						image.push("$BUILD_ID")
						image.push('latest') }
				}}
			post { success {
				sh 'docker rmi -f ${dockerImage}'
				sh 'docker builder prune --all -f'
			} }
		}
		stage('Fetch from Nexus & Deploy using Ansible') {
			agent { label 'agent1' }
			when { expression { return params.AnsibleDeploy }}
			steps{
				script{
					dir('ansible'){
						echo "${params.AnsibleDeploy}"
						sh 'ansible-playbook deployment.yml -e NEXUS_ARTIFACT=${NEXUS_ARTIFACT} -v > live_log.txt || exit 1'
						sh 'tail -2 live_log.txt'}
				}}
			post { always { archiveArtifacts artifacts: "ansible/live_log.txt", fingerprint: true } }
		} 
		stage('Deploy to EKS') {
			agent { label 'agent1' }
			when { expression { return params.EksDeploy }}
			steps {
				script{
					dir('k8s'){
						sh "chmod +x ./cluster.sh && ./cluster.sh" 
						sh '''kubectl apply -f ./eksdeploy.yml
                                                kubectl get deployments && sleep 5 && kubectl get svc
						'''   }}}
			post { always { cleanWs() } }
		}
	}
	post { always { cleanWs() } }
}
