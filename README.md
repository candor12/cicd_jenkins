#### Jenkins - Maven - SonarQube - Nexus - Docker -ECR - Ansible - EKS
git branch -a | grep -v master | cut -d "/" -f3 > branches.txt
for i in `cat branches.txt`; do git checkout $i; done
