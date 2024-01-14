def branch = 'Tag'
def repoUrl = 'https://github.com/candor12/cicd_jenkins.git'

pipeline {
	agent any
	options{
		 skipDefaultCheckout() 
	}
	environment {
		artifactId = readMavenPom().getArtifactId()    //Use Pipeline Utility Steps
		pomVersion = readMavenPom().getVersion()
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
				withCredentials([[$class: 'UsernamePasswordMultiBinding',
						  credentialsId: 'gitPAT',
						  usernameVariable: 'GIT_USERNAME',
						  passwordVariable: 'GIT_PASSWORD']]) {
					sh '''git tag ${gitTag}
                                        git push --tags 
					echo "https://github.com/candor12/cicd_jenkins/tree/${gitTag}"
					'''
					echo "Tag pushed to repository: ${gitTag}" 
				}
			}
		} 
	}
}
