#!/bin/bash
yum update -y
yum -y install yum-utils device-mapper-persistent-data lvm2 git
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce
systemctl enable docker
systemctl start docker
echo 'vm.max_map_count=262144' >> /etc/sysctl.conf sysctl -p
usermod -aG docker centos
curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose
git clone https://github.com/joelckwong/jenkins-sonaqube-pipeline.git /home/centos/jenkins-sonaqube-pipeline
chown -R centos: /home/centos/jenkins-sonaqube-pipeline
cp /home/centos/jenkins-sonaqube-pipeline/docker-compose.service /etc/systemd/system
systemctl enable docker-compose.service
systemctl start docker-compose.service
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=8081/tcp --permanent
firewall-cmd --zone=public --add-port=9000/tcp --permanent
firewall-cmd --reload
