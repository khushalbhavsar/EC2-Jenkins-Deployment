# 🚀 Jenkins Setup on AWS EC2 with Git and Docker

This guide walks you through setting up **Jenkins** on an **AWS EC2 instance** with **Git** and **Docker** integration — ideal for CI/CD automation.

---

## 🧰 Prerequisites

| Requirement | Description |
|--------------|-------------|
| **AWS EC2 Instance** | Amazon Linux 2023 (t3.large recommended) |
| **Storage** | 30 GB SSD |
| **Key Pair** | `jenkins.pem` (ensure correct permissions) |
| **Security Group Ports** | SSH (22), HTTP (80), HTTPS (443), Jenkins (8080) |

---

## ⚙️ Step 1: Connect to EC2 Instance

```bash
cd Downloads
chmod 400 jenkins.pem
ssh -i "jenkins.pem" ec2-user@<YOUR_EC2_PUBLIC_IP>
```

---

## 📦 Step 2: Install Required Packages

### 1. Update and Install Git

```bash
sudo yum update -y
sudo yum install git -y
git --version
```

(Optional) Configure Git:

```bash
git config --global user.name "Atul Kamble"
git config --global user.email "atul_kamble@hotmail.com"
git config --list
```

---

### 2. Install Docker

```bash
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
docker --version
```

---

### 3. Install Java (Amazon Corretto 21)

```bash
sudo dnf install java-21-amazon-corretto -y
# OR
sudo yum install fontconfig java-21-openjdk -y
java --version
```

---

### 4. Install Maven

```bash
sudo yum install maven -y
mvn -v
```

---

### 5. Install Jenkins

```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
sudo yum install jenkins -y
jenkins --version
```

---

### 6. Add Jenkins User to Docker Group

```bash
sudo usermod -aG docker jenkins
```

---

## ▶️ Step 3: Start Jenkins

```bash
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

---

## 🌐 Step 4: Access Jenkins Web UI

Open your browser and go to:

```text
http://<YOUR_EC2_PUBLIC_IP>:8080
```

Unlock Jenkins using the initial admin password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Paste the password into the Jenkins setup screen and complete the setup.

---

## 🐳 Jenkins Using Docker (Alternative Setup)

After SSH into EC2:

```bash
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
docker --version
sudo docker login
sudo docker images
sudo docker pull jenkins/jenkins:jdk21
sudo docker run -d -p 8080:8080 jenkins/jenkins:jdk21
```

Browse Jenkins:

```text
http://<YOUR_EC2_PUBLIC_IP>:8080
```

List running containers:

```bash
sudo docker container ls
```

Get Jenkins initial password:

```bash
sudo docker exec -it <container_id> cat /var/jenkins_home/secrets/initialAdminPassword
```

Example:

```bash
sudo docker exec -it da6e91230c61 cat /var/jenkins_home/secrets/initialAdminPassword
```

---

## 🧾 Quick Deployment Script

```bash
git clone https://github.com/atulkamble/ec2-jenkins.git
cd ec2-jenkins
chmod +x deploy.sh
./deploy.sh
```

---

## ✅ Jenkins is Now Ready!

You have successfully set up Jenkins on AWS EC2 with Git and Docker integration. Use it to build, test, and deploy your CI/CD pipelines efficiently.
