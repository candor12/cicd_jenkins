
pipeline {
	options {
		buildDiscarder(logRotator(numToKeepStr: '10'))
                skipDefaultCheckout() 
                disableConcurrentBuilds()
	}
	agent any
	parameters {
		booleanParam(name: "EksDeploy", defaultValue: false, description: "Deploy the Build to EKS")
		booleanParam(name: "AnsibleDeploy", defaultValue: false, description: "Deploy the Build to Target Server using Ansible")
		booleanParam(name: "SonarQube", defaultValue: false, description: "By Pass SonarQube Scan")
		booleanParam(name: "Trivy", defaultValue: false, description: "By Pass Trivy Scan")
	}	
	environment {
		branch               = 'nexus-mvn-deploy'
		repoUrl              = 'https://github.com/candor12/cicd_jenkins.git'
		gitCreds             = 'gitPAT'
		gitTag               = "${env.pomVersion}-${env.BUILD_TIMESTAMP}"
		NEXUS_VERSION        = "nexus3"
                NEXUS_PROTOCOL       = "http"	    
                NEXUS_URL            = "172.31.17.3:8081"
                NEXUS_REPOSITORY     = "team-artifacts"
	        NEXUS_REPO_ID        = "team-artifacts"
                NEXUS_CREDENTIAL_ID  = "nexuslogin"
                ARTVERSION           = "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}"
	        NEXUS_ARTIFACT       = "${env.NEXUS_PROTOCOL}://${env.NEXUS_URL}/repository/${env.NEXUS_REPOSITORY}/com/team/project/tmart/${env.ARTVERSION}/tmart-${env.ARTVERSION}.war"
	        scannerHome          = tool 'sonar4.7'
	        ecr_repo             = '674583976178.dkr.ecr.us-east-2.amazonaws.com/teamimagerepo'
                ecrCreds             = 'awscreds'
	        dockerImage          = "${env.ecr_repo}:${env.BUILD_ID}"
		pomVersion           = sh(returnStdout: true, script: 'mvn -DskipTests help:evaluate -Dexpression=project.version -q -DforceStdout')
	}
	stages{
		stage('SCM Checkout'){
			steps{
				git branch: branch, url: repoUrl, credentialsId: 'gitPAT'
		}}
		stage('Maven Build'){
			steps {
				sh 'mvn clean install -DskipTests'
			}}
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
					sh "mvn deploy -DskipTests -Dmaven.install.skip=true"
					echo "${NEXUS_ARTIFACT}"
					}}}
		stage('Add Tag to Repository') {
			steps { withCredentials([usernamePassword(credentialsId: 'gitPAT',usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]){
				sh '''
                                git tag ${gitTag}
                                git push --tags 
				'''
				echo "Tag pushed to repository: ${gitTag}" 
				}}
		} 
		/*
		stage('Docker Image Build') {
			agent { label 'agent1' }
			steps {
				script {
					git branch: 'master', url: 'https://github.com/azka-begh/CICD-with-Jenkins.git'
					image = docker.build(ecr_repo + ":$BUILD_ID", "./") 
				}}}
		stage ('Trivy Scan') {
			agent { label 'agent1' }
			when { not{ expression { return params.Trivy  }}}
			steps{
				script {
					 sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl > ./html.tpl'
				         sh 'trivy image --skip-db-update --skip-java-db-update --cache-dir ~/trivy/ --format template --template \"@./html.tpl\" -o trivy.html --severity MEDIUM,HIGH,CRITICAL ${dockerImage}' 
				}}
			post { always { archiveArtifacts artifacts: "trivy.html", fingerprint: true
				                     publishHTML target : [allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true,
									   reportDir: './', reportFiles: 'trivy.html', reportName: 'Trivy Scan', reportTitles: 'Trivy Scan']
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
		} */
	}
	post { always { cleanWs() } }
}
