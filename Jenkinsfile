pipeline {
	agent any
	options{
		 skipDefaultCheckout() 
	}
	environment {
		branch     = 'Tag'
		repoUrl    = 'https://github.com/candor12/cicd_jenkins.git'
		gitCreds   = 'gitPAT'
		artifactId = sh(returnStdout: true, script: 'mvn -DskipTests help:evaluate -Dexpression=project.artifactId -q -DforceStdout')
		groupId    = sh(returnStdout: true, script: 'mvn -DskipTests help:evaluate -Dexpression=project.groupId -q -DforceStdout')
		pomVersion = sh(returnStdout: true, script: 'mvn -DskipTests help:evaluate -Dexpression=project.version -q -DforceStdout')
		packaging  = sh(returnStdout: true, script: 'mvn -DskipTests help:evaluate -Dexpression=project.packaging -q -DforceStdout')
		gitTag     = "${env.pomVersion}-${env.BUILD_TIMESTAMP}"
	}
	stages {
		stage('Checkout SCM') {
			steps {
				git branch: branch, credentialsId: 'gitPAT', url: 'repoUrl'
			}}
		stage('Add Tag') {
			steps {
				withCredentials([usernamePassword(credentialsId: 'gitPAT',usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]){
					sh '''
                                        git tag ${gitTag}
                                        git push --tags 
					'''
					echo "Tag pushed to repository: ${gitTag}" 
				}}
		} 
	}
}
