pipeline {
	options {
		buildDiscarder(logRotator(numToKeepStr: '8'))
                skipDefaultCheckout() 
                disableConcurrentBuilds() }
	
	agent any
	
	parameters {
		booleanParam(name: "EksDeploy", defaultValue: false, description: "Deploy the Build to EKS")
		booleanParam(name: "AnsibleDeploy", defaultValue: false, description: "Deploy the Build to Target Server using Ansible")
		booleanParam(name: "SonarQube", defaultValue: false, description: "By Pass SonarQube Scan")
		booleanParam(name: "Trivy", defaultValue: false, description: "By Pass Trivy Scan") }
	
	environment {
		pomVersion       =       sh(returnStdout: true, script: "mvn -DskipTests help:evaluate -Dexpression=project.version -q -DforceStdout")
		branch           =       "correct"
		repoUrl          =       "https://github.com/candor12/cicd_jenkins.git"
		gitCreds         =       "gitPAT"
		gitTag           =       "${env.pomVersion}-${env.BUILD_TIMESTAMP}"
	        scannerHome      =       tool 'sonar4.7'
	        ecrRepo         =        "674583976178.dkr.ecr.us-east-2.amazonaws.com/teamimagerepo"
                ecrCreds         =       "awscreds"
	        dockerImage      =       "${env.ecr_repo}:${env.BUILD_ID}" }
	
	stages{
		stage('SCM Checkout') {
			steps {
				git branch: branch, url: repoUrl, credentialsId: 'gitPAT'
		}}
		stage('Build Artifact') {
			steps {
				sh 'mvn clean install -DskipTests'
			}}
		stage('SonarQube Scan') {
			when { not { expression { return params.SonarQube  }}}
			tools { jdk "jdk-11" }
			steps {
				script { withSonarQubeEnv('sonar') {
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
					sh "mvn deploy -DskipTests -Dmaven.install.skip=true > nexus.log && cat nexus.log"
					def artifactUrl = sh(returnStdout: true, script: 'tail -20 nexus.log | grep ".war" nexus.log | grep -v INFO | grep -v Uploaded') 
					NEXUS_ARTIFACT = artifactUrl.drop(20)    //groovy
					echo "Artifact URL: ${NEXUS_ARTIFACT}"
					}}}
		stage('Push Tag to Repository') {
			steps { withCredentials([usernamePassword(credentialsId: 'gitPAT',usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
				sh '''
                                git tag ${gitTag}
                                git push --tags 
				'''
				echo "Tag pushed to repository: ${gitTag}" 
				}}} 
		stage('Docker Image Build') {
			agent { label 'agent1' }
			steps {
				script { cleanWs()
					git branch: branch, url: repoUrl
					sh 'docker build -t $dockerImage ./'
					sh 'docker tag $dockerImage $ecrRepo:latest'
				}}}
		stage ('Trivy Scan') {
			agent { label 'agent1' }
			when { not { expression { return params.Trivy  }}}
			steps {
				script {
					 sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl > ./html.tpl'
				         sh 'trivy image --skip-db-update --skip-java-db-update --cache-dir ~/trivy/ --format template --template \"@./html.tpl\" -o trivy.html --severity MEDIUM,HIGH,CRITICAL ${dockerImage}' 
				}}
			post { always { archiveArtifacts artifacts: "trivy.html", fingerprint: true
				                     publishHTML target : [allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true,
									   reportDir: './', reportFiles: 'trivy.html', reportName: 'Trivy Scan', reportTitles: 'Trivy Scan']
				      }}}		
		stage('Push Image to ECR') {
			agent { label 'agent1' }
			steps {
				script {
					def status = sh(returnStatus: true, script: 'docker push $dockerImage')
					if (status != 0){
					    sh "aws ecr get-authorization-token --region us-east-2 --output text --query 'authorizationData[].authorizationToken' | base64 -d | cut -d: -f2 > ecr.txt"
                                            sh 'cat ecr.txt | docker login -u AWS 674583976178.dkr.ecr.us-east-2.amazonaws.com --password-stdin'
					    sh 'docker push $dockerImage'
				    }
					sh "docker push ${ecrRepo}:latest"
				}}
			post { always {
				sh """ rm -f ecr.txt
				docker rmi -f ${dockerImage}
				docker rmi -f ${ecrRepo}:latest
				""" }
			}}
		stage('Fetch from Nexus & Deploy using Ansible') {
			agent { label 'agent1' }
			when { expression { return params.AnsibleDeploy }}
			steps {
				script{ dir('ansible') {
					sh "ansible-playbook deployment.yml -e NEXUS_ARTIFACT=$NEXUS_ARTIFACT" }
				}}} 
		stage('EKS Deployment') {
			agent { label 'agent1' }
			when { expression { return params.EksDeploy }}
			steps {
				script { dir('k8s') {
					sh "chmod +x ./cluster.sh && ./cluster.sh" 
					sh '''kubectl apply -f ./eksdeploy.yml
                                        kubectl get deployments && sleep 5 && kubectl get svc
				        '''   }}}
			post { always { cleanWs() } }
		} 
	} 
	post { always { cleanWs() } }
}
