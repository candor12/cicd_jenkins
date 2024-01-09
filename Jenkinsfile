def branch = 'Tag'
def repoUrl = 'https://github.com/azka-begh/cicd-with-jenkins.git'

pipeline {
    agent any
    stages {
        stage('Checkout example-app') {
            steps {
		    script{
                     git branch: branch,
                     credentialsId: 'gitCred',
                     url: repoUrl
		    currentDateTime = sh script: """
                        date +"-%Y%m%d_%H%M"
                        """.trim(), returnStdout: true
                    version = currentDateTime.trim()  // the .trim() is necessary
                    echo "version: " + version
            }}
        }
       
        stage('Build and deploy') {
            ...
        }
        stage('Adding the version to the latest commit as a tag') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding',
                        credentialsId: 'gitCred',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD']]) {
                    sh '''
                        git config --global credential.username $GIT_USERNAME
                        git config --global credential.helper '!f() { echo password=$GIT_PASSWORD; }; f'
                    '''
                    sh """
                        git tag ${version}
                        git push ${repoUrl} --tags
                    """
                }
            }
        }
    }
}
