# EC2 + Jenkins (Terraform + Docker) — Quick Start

This repository contains Terraform configuration and helper scripts to provision an EC2 instance and run Jenkins (either via Docker or the native package). The instructions below provide a concise, step-by-step workflow: prerequisites, deploy (Terraform + script), optional Docker-based Jenkins, access, and cleanup.

## Repo contents (important files)

* `main.tf`, `variables.tf`, `outputs.tf` — Terraform configuration for EC2 and related resources
* `deploy.sh` — helper script to finalize deployment on the instance (bootstrap)
* `Jenkinsfile` — sample pipeline definition

## Prerequisites

* An AWS account and an IAM user with permissions to create EC2, security groups, key pairs, and related resources
* Terraform >= 1.0 installed locally
* SSH client (macOS/Linux) or PowerShell/WSL on Windows
* A key pair for SSH access (or allow Terraform to create one)
* Recommended EC2 type: `t3.large` or similar (adjust for your load)

Open ports in the instance Security Group (or LB) as appropriate:

* SSH: 22 (restrict to your IP)
* Jenkins: 8080 (or restrict via a load balancer / VPN)
* HTTP: 80 and HTTPS: 443 as needed

> Note: The examples below assume Amazon Linux / RHEL-style package manager (yum/dnf). Adjust package manager commands for Ubuntu/Debian (apt).

---

## Quick start (recommended)

1. Clone this repository locally:

```bash
git clone https://github.com/khushalbhavsar/EC2-Jenkins-Deployment.git
cd EC2-Jenkins-Deployment
```

1. Inspect and optionally edit `variables.tf` to set region, instance type, key pair name, and other variables.

1. Initialize and apply Terraform (creates EC2, security group, outputs):

```bash
terraform init
terraform plan -out plan.tfplan
terraform apply "plan.tfplan"
```

After `apply` completes, note the public IP or DNS in the Terraform outputs. You can view outputs with:

```bash
terraform output
```

1. SSH to the created EC2 instance (example):

On macOS/Linux:

```bash
chmod 400 path/to/jenkins.pem
ssh -i path/to/jenkins.pem ec2-user@<EC2_PUBLIC_IP>
```

On Windows (PowerShell):

```powershell
# Using OpenSSH in PowerShell
ssh -i C:\\path\\to\\jenkins.pem ec2-user@<EC2_PUBLIC_IP>
```

1. (Optional) Run the included bootstrap script on the instance:

```bash
chmod +x deploy.sh
./deploy.sh
```

`deploy.sh` is intended to perform convenience tasks on the instance (install packages, configure users, etc.). Inspect the script before running it.

---

## Option A — Run Jenkins as a Docker container (fast)

Execute the following commands on the EC2 instance after SSH.

1. Update packages and install Docker

```bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo docker --version
```

1. (Optional) Login to Docker Hub if you need private images

```bash
sudo docker login
```

1. Pull and run Jenkins (example using JDK21 image)

```bash
sudo docker pull jenkins/jenkins:jdk21
sudo docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:jdk21
```

1. Get the initial admin password

```bash
sudo docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

1. Open Jenkins in your browser:

```text
http://<EC2_PUBLIC_IP>:8080
```

Use the password from step 4 to complete the first-time setup.

---

## Option B — Install Jenkins via OS package (systemd)

If you prefer to install the native Jenkins package on Amazon Linux/RHEL:

```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
sudo yum install -y jenkins java-17-amazon-corretto
sudo systemctl enable --now jenkins
sudo systemctl status jenkins
```

Retrieve the initial password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Then browse to `http://<EC2_PUBLIC_IP>:8080`.

---

## Post-deploy notes

* Add the `jenkins` user to the `docker` group if you plan to run Docker builds from Jenkins:

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

* Configure security: tighten security group rules, use HTTPS, and consider placing Jenkins behind a load balancer or VPN.

---

## Cleanup / Tear down

Remove Docker container (if used):

```bash
sudo docker rm -f jenkins || true
sudo docker volume rm jenkins_home || true
```

Destroy Terraform-managed infrastructure from your local machine:

```bash
terraform destroy
```

---

## Troubleshooting

* If SSH fails, ensure the Security Group allows your IP on port 22 and the key pair matches.
* If Jenkins UI is unreachable, verify that the instance's security group allows port 8080 and the Docker container is running (`sudo docker ps`).
* Check logs:

```bash
sudo docker logs jenkins         # container logs
sudo journalctl -u jenkins -f  # systemd-installed Jenkins
```

---

## Files of interest

* `deploy.sh` — instance bootstrap helper (review before running)
* `main.tf`, `variables.tf`, `outputs.tf` — Terraform resources and variables
* `Jenkinsfile` — example CI/CD pipeline

---

If you'd like, I can also:

* add a checklist to the repo root `00 steps.md` with an exact sequence for a first-time run, or
* create a minimal `Makefile` or PowerShell helper to wrap the Terraform commands for Windows users.

Tell me which focus you prefer (Docker vs. native Jenkins vs. Terraform-only) and I will tailor the README accordingly.

   > Repo contents (important files)

   - `main.tf`, `variables.tf`, `outputs.tf` — Terraform configuration for EC2 and related resources
   - `deploy.sh` — helper script to finalize deployment on the instance (bootstrap)
   - `Jenkinsfile` — sample pipeline definition

   ## Prerequisites

   - An AWS account and IAM user with permissions to create EC2, security groups, key pairs, and related resources
   - Terraform >= 1.0 installed locally
   - SSH client (macOS/Linux) or PowerShell/WSL on Windows
   - A key pair for SSH access (or allow Terraform to create one)
   - Recommended EC2 type: t3.large or similar (adjust for your load)

   Open ports in the instance Security Group (or LB) as appropriate:

   - SSH: 22 (restrict to your IP)
   - Jenkins: 8080 (or restrict via a load balancer / VPN)
   - HTTP: 80 and HTTPS: 443 as needed

   Note: The examples below assume Amazon Linux / RHEL-style package manager (yum/dnf). Adjust package manager commands for Ubuntu/Debian (apt).

   ---

   ## Quick start (recommended)

   1. Clone this repository locally:

   ```
   git clone https://github.com/khushalbhavsar/EC2-Jenkins-Deployment.git
   cd EC2-Jenkins-Deployment
   ```

   2. Inspect and optionally edit `variables.tf` to set region, instance type, key pair name, and other variables.

   3. Initialize and apply Terraform (creates EC2, security group, outputs):

   ```
   terraform init
   terraform plan -out plan.tfplan
   terraform apply "plan.tfplan"
   ```

   After `apply` completes, note the public IP or DNS in the Terraform outputs. You can view outputs with:

   ```
   terraform output
   ```

   4. SSH to the created EC2 instance (example):

   On macOS/Linux:

   ```
   chmod 400 path/to/jenkins.pem
   ssh -i path/to/jenkins.pem ec2-user@<EC2_PUBLIC_IP>
   ```

   On Windows (PowerShell):

   ```powershell
   # Using OpenSSH in PowerShell
   ssh -i C:\\path\\to\\jenkins.pem ec2-user@<EC2_PUBLIC_IP>
   ```

   5. Run the included bootstrap script (optional):

   ```
   chmod +x deploy.sh
   ./deploy.sh
   ```

   `deploy.sh` is intended to perform convenience tasks on the instance (install packages, configure users, etc.). Inspect the script before running it.

   ---

   ## Option A — Run Jenkins as a Docker container (fast)

   These commands are executed on the EC2 instance after SSH.

   1. Update packages and install Docker

   ```
   sudo yum update -y
   sudo yum install -y docker
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo docker --version
   ```

   2. (Optional) Login to Docker Hub if you need private images

   ```
   sudo docker login
   ```

   3. Pull and run Jenkins (example using JDK21 image)

   ```
   sudo docker pull jenkins/jenkins:jdk21
   sudo docker run -d --name jenkins \
     -p 8080:8080 -p 50000:50000 \
     -v jenkins_home:/var/jenkins_home \
     jenkins/jenkins:jdk21
   ```

   4. Get the initial admin password

   ```
   sudo docker exec -it jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

   5. Open Jenkins in your browser:

   ```
   http://<EC2_PUBLIC_IP>:8080
   ```

   Use the password from step 4 to complete the first-time setup.

   ---

   ## Option B — Install Jenkins via OS package (systemd)

   If you prefer to install the native Jenkins package on Amazon Linux/RHEL:

   ```
   sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
   sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
   sudo yum upgrade -y
   sudo yum install -y jenkins java-17-amazon-corretto
   sudo systemctl enable --now jenkins
   sudo systemctl status jenkins
   ```

   Retrieve the initial password:

   ```
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

   Then browse to `http://<EC2_PUBLIC_IP>:8080`.

   ---

   ## Post-deploy notes

   - Add the `jenkins` user to the `docker` group if you plan to run Docker builds from Jenkins:

   ```
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   ```

   - Configure security: tighten security group rules, use HTTPS, and consider placing Jenkins behind a load balancer or VPN.

   ---

   ## Cleanup / Tear down

   Remove Docker container (if used):

   ```
   sudo docker rm -f jenkins || true
   sudo docker volume rm jenkins_home || true
   ```

   Destroy Terraform-managed infrastructure from your local machine:

   ```
   terraform destroy
   ```

   ---

   ## Troubleshooting

   - If SSH fails, ensure the Security Group allows your IP on port 22 and the key pair matches.
   - If Jenkins UI is unreachable, verify that the instance's security group allows port 8080 and the Docker container is running (`sudo docker ps`).
   - Check logs:

   ```
   sudo docker logs jenkins         # container logs
   sudo journalctl -u jenkins -f  # systemd-installed Jenkins
   ```

   ---

   ## Files of interest

   - `deploy.sh` — instance bootstrap helper (review before running)
   - `main.tf`, `variables.tf`, `outputs.tf` — Terraform resources and variables
   - `Jenkinsfile` — example CI/CD pipeline

   If you'd like, I can also:

   - add a checklist to the repo root `00 steps.md` with an exact sequence for a first-time run, or
   - create a minimal `Makefile` or PowerShell helper to wrap the Terraform commands for Windows users.

   ---

   If you want this README shortened, or adjusted to target only Docker/native Jenkins or only Terraform, tell me which focus you prefer and I will update accordingly.
