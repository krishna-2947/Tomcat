#!/bin/bash

# Install Apache Tomcat 10 on Ubuntu 22.04

TOMCAT_USER=tomcat
INSTALL_DIR=/opt/tomcat

echo "Installing Java (required for Tomcat)..."
sudo apt update -y
sudo apt install default-jdk -y

echo "Fetching latest Tomcat 10 version..."
LATEST_VERSION=$(curl -s https://dlcdn.apache.org/tomcat/tomcat-10/ | grep -oP 'v10\.\d+\.\d+/' | sort -V | tail -n1 | tr -d '/')
echo "Latest version is $LATEST_VERSION"

echo "Creating tomcat user..."
sudo useradd -m -U -d $INSTALL_DIR -s /bin/false $TOMCAT_USER

echo "Downloading Apache Tomcat $LATEST_VERSION..."
cd /tmp
wget https://dlcdn.apache.org/tomcat/tomcat-10/$LATEST_VERSION/bin/apache-tomcat-${LATEST_VERSION#v}.tar.gz

echo "Extracting Tomcat..."
sudo mkdir -p $INSTALL_DIR
sudo tar -xzf apache-tomcat-${LATEST_VERSION#v}.tar.gz -C $INSTALL_DIR --strip-components=1

echo "Setting permissions..."
sudo chown -R $TOMCAT_USER:$TOMCAT_USER $INSTALL_DIR
sudo chmod +x $INSTALL_DIR/bin/*.sh

echo "⚙Creating systemd service file..."
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=$TOMCAT_USER
Group=$TOMCAT_USER

Environment="JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")"
Environment="CATALINA_PID=$INSTALL_DIR/temp/tomcat.pid"
Environment="CATALINA_HOME=$INSTALL_DIR"
Environment="CATALINA_BASE=$INSTALL_DIR"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.security.egd=file:/dev/./urandom"

ExecStart=$INSTALL_DIR/bin/startup.sh
ExecStop=$INSTALL_DIR/bin/shutdown.sh

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd and starting Tomcat..."
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat

echo "Checking Tomcat status..."
sudo systemctl status tomcat | grep Active

echo "Done. Access Tomcat at: http://<your-ip>:8080"
