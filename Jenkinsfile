def branch = 'Tag'
def repoUrl = 'https://github.com/candor12/cicd_jenkins.git'

pipeline {
    agent any
	environment {
        artifactId = readMavenPom().getArtifactId()    //Use Pipeline Utility Steps
        pomVersion = readMavenPom().getVersion()
	gitTag = "${env.pomVersion}-${env.BUILD_TIMESTAMP}"
    }
    stages {
        stage('Checkout SCM') {
            steps {
		    script{
                     git branch: branch,
                     credentialsId: 'gitPAT',
                     url: repoUrl
		     echo "version: ${gitTag}" 
		    
		   // currentDateTime = sh script: """ date +"-%Y%m%d_%H%M" """.trim(), returnStdout: true
                  //  version = currentDateTime.trim()  // the .trim() is necessary
                    
            }}
        }
       
        stage('Add Tag') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding',
                        credentialsId: 'gitPAT',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD']]) {
                  /*  sh '''
                        git config --global credential.username $GIT_USERNAME
                        git config --global credential.helper '!f() { echo password=$GIT_PASSWORD; }; f'
                    ''' */
                    sh """
                        git tag ${gitTag}
                        git push ${repoUrl} --tags
                    """
                }
            }
        }
    }
}
