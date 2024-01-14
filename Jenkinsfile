def branch = 'Tag'
def repoUrl = 'https://github.com/candor12/cicd_jenkins.git'

def pomVersion = sh script: 'mvn -DskipTests help:evaluate -Dexpression=project.version -q -DforceStdout', returnStdout: true;
def artifactId = sh script: 'mvn -DskipTests help:evaluate -Dexpression=project.artifactId -q -DforceStdout', returnStdout: true;
def groupId = sh script: 'mvn -DskipTests help:evaluate -Dexpression=project.groupId -q -DforceStdout', returnStdout: true;
def packaging = sh script: 'mvn -DskipTests help:evaluate -Dexpression=project.packaging -q -DforceStdout', returnStdout: true;

pipeline {
	agent any
	options{
		 skipDefaultCheckout() 
	}
	environment {
		//artifactId = readMavenPom().getArtifactId()    //Use Pipeline Utility Steps
		//pomVersion = readMavenPom().getVersion()
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
