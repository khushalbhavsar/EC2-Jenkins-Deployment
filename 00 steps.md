```
amazon linux | t2.large | ssd - 40GB | SG - jenkins-8080

cd Downloads
chmod 400 jenkins.pem 
ssh -i "jenkins.pem" ec2-user@ec2-54-167-113-182.compute-1.amazonaws.com

sudo yum install git docker tree -y
sudo systemctl start docker
sudo systemctl enable docker
git config --global user.email "atul_kamble@hotmail.com"
git config --global user.name "Atul Kamble"
git config --list

sudo yum install java-21-amazon-corretto.x86_64 -y
java --version

// https://www.jenkins.io/doc/book/installing/linux/#red-hat-centos

sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade
# Add required dependencies for the jenkins package
sudo yum install fontconfig java-21-openjdk
sudo yum install jenkins
sudo systemctl daemon-reload

jenkins --version 

sudo systemctl start jenkins
sudo systemctl enable jenkins

sudo usermod -aG docker jenkins 

http://54.167.113.182:8080

sudo cat /var/lib/jenkins/secrets/initialAdminPassword

// paste password to Jenkins Server 

// Install suggested Plugins 

// add username, password, Name, Email

settings >> plugins >> available plugins >> blue ocean, docker, docker pipeline etc.

settings >> Tools >> git, myMaven, myJDK, myDocker | install automatically

pipeline { 
     agent any 
  
     stages { 
         stage('Dev') { 
             steps { 
                 echo 'I am in dev' 
                 sh 'git --version' 
             } 
         } 
         stage('Test') { 
             steps { 
                 echo 'I am in test' 
                 sh 'docker --version' 
             } 
         } 
         stage('Prod') { 
             steps { 
                 echo 'Application Deployed' 
             } 
         } 
     } 
 }

```
