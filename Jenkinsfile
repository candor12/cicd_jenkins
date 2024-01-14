def repoUrl = 'https://github.com/candor12/cicd_jenkins.git'

pipeline {
	agent any
	options{
		 skipDefaultCheckout() 
	}
	environment {
		def branch = '${env.BRANCH_NAME}'
		//artifactId = readMavenPom().getArtifactId()    //Use Pipeline Utility Steps
		//pomVersion = readMavenPom().getVersion()
		def pomVersion = sh(returnStdout: true, script: 'mvn -DskipTests help:evaluate -Dexpression=project.version -q -DforceStdout')
		def artifactId = sh(returnStdout: true, script: 'mvn -DskipTests help:evaluate -Dexpression=project.artifactId -q -DforceStdout')
		def groupId = sh(returnStdout: true, script: 'mvn -DskipTests help:evaluate -Dexpression=project.groupId -q -DforceStdout')
		def packaging = sh(returnStdout: true, script: 'mvn -DskipTests help:evaluate -Dexpression=project.packaging -q -DforceStdout')
		gitTag = "${env.pomVersion}-${env.BUILD_TIMESTAMP}"
		gitCreds = 'gitPAT'
	}
	stages {
		stage('Checkout SCM') {
			steps {
				git branch: branch, credentialsId: 'gitPAT', url: repoUrl
			}}
		stage('Add Tag') {
			steps {
				withCredentials([usernamePassword(credentialsId: 'gitPAT',usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]){
					sh '''git tag ${gitTag}
                                        git push --tags 
					'''
					echo "Tag pushed to repository: ${gitTag}" 
				}
			}
		} 
	}
}
