#!/bin/bash

# Auto-install tools toggle: set INSTALL_TOOLS=false to skip automatic installation
INSTALL_TOOLS=${INSTALL_TOOLS:-true}
echo "INSTALL_TOOLS=$INSTALL_TOOLS"

# Update system
sudo yum update -y

# Install common tools if enabled
if [ "$INSTALL_TOOLS" = "true" ] || [ "$INSTALL_TOOLS" = "1" ]; then
	echo "Installing tools: git, docker, maven, ant, wget"
	# Install packages via yum (idempotent)
	sudo yum install -y git docker maven ant wget || true

	# Install Amazon Corretto 21 (Java) if not already present or not Corretto
	if ! command -v java >/dev/null 2>&1 || ! java -version 2>&1 | grep -qi "Corretto"; then
		echo "Installing Amazon Corretto 21 (Java)"
		sudo dnf install -y java-21-amazon-corretto || echo "Failed to install Corretto via dnf"
	else
		echo "Java (Corretto) already installed"
	fi
else
	echo "Skipping automatic tool installation (INSTALL_TOOLS=$INSTALL_TOOLS)"
fi

# Git configuration
git --version
git config --global user.name "Atul Kamble"
git config --global user.email "atul_kamble@hotmail.com"
git config --list

# Start and enable Docker if installed
if command -v docker >/dev/null 2>&1; then
	sudo systemctl start docker
	sudo systemctl enable docker
	# Add ec2-user and jenkins to docker group (ignore errors if users don't exist yet)
	sudo usermod -aG docker ec2-user || true
	sudo usermod -aG docker jenkins || true
else
	echo "Docker not installed or not in PATH; skipping docker service start/group modification"
fi

# Print Java version
if command -v java >/dev/null 2>&1; then
	java --version
else
	echo "Java not found"
fi

# Install Jenkins
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
sudo yum install -y jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Print Jenkins and Maven versions
jenkins --version || echo "Jenkins installed"
mvn -v

# Fetch instance public IP from AWS instance metadata (if running on EC2) and print Jenkins URL
if command -v curl >/dev/null 2>&1; then
	# IMDSv2 token
	TOKEN=$(curl -s -m 5 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60") || TOKEN=""
	if [ -n "$TOKEN" ]; then
		PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)
	else
		PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
	fi
	if [ -n "$PUBLIC_IP" ]; then
		echo "Jenkins UI: http://$PUBLIC_IP:8080"
	else
		echo "Jenkins UI: http://<public-ip>:8080  (public IP not found via instance metadata)"
	fi
else
	echo "curl not available; cannot query instance metadata for public IP. Jenkins UI: http://<instance-ip>:8080"
fi

	# Install recommended Jenkins plugins (docker, docker-pipeline, Blue Ocean)
	# Uses jenkins-plugin-cli (bundled with recent Jenkins packages). Run as root so it can write to JENKINS_HOME.
	if command -v jenkins-plugin-cli >/dev/null 2>&1; then
		echo "Installing Jenkins plugins: docker-plugin, docker-workflow, blueocean"
		# retry a couple times in case network is flaky
		for attempt in 1 2 3; do
			if jenkins-plugin-cli --plugins docker-plugin docker-workflow blueocean; then
				echo "Plugins installed successfully"
				break
			else
				echo "Plugin install attempt $attempt failed, retrying in 5s..."
				sleep 5
			fi
		done
	else
		echo "jenkins-plugin-cli not found. Attempting to install plugins by placing .hpi files is unsupported in this script."
		echo "If plugins are required, install jenkins-plugin-cli or manually add plugins to /var/lib/jenkins/plugins and restart Jenkins."
	fi

	# Restart Jenkins to load new plugins and wait until the HTTP endpoint responds
	sudo systemctl restart jenkins
	echo "Waiting for Jenkins to become available on localhost:8080"
	# Use a proper loop range to wait up to ~150s (30 * 5s)
	for i in {1..30}; do
		if command -v curl >/dev/null 2>&1 && curl -sSf http://127.0.0.1:8080 >/dev/null 2>&1; then
			echo "Jenkins is up"
			break
		fi
		echo "Waiting... ($i/30)"
		sleep 5
	done

	# At the very end, attempt to print the initial admin password (with retries)
	PASSWORD_FILE=/var/lib/jenkins/secrets/initialAdminPassword
	echo "Attempting to print Jenkins initial admin password (if available) at: $PASSWORD_FILE"
	# Retry for up to 2 minutes (24 * 5s)
	for i in {1..24}; do
		if [ -f "$PASSWORD_FILE" ]; then
			echo "=== Jenkins initialAdminPassword ==="
			sudo cat "$PASSWORD_FILE" || echo "Failed to read $PASSWORD_FILE with sudo"
			echo "=== end ==="
			break
		fi
		echo "Password file not present yet, retrying... ($i/24)"
		sleep 5
	done
	if [ ! -f "$PASSWORD_FILE" ]; then
		echo "Password file still not found at $PASSWORD_FILE after waiting. You can retrieve it manually on the server with:"
		echo "  sudo cat $PASSWORD_FILE"
	fi
