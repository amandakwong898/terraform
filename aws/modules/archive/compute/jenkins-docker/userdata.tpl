#!/bin/bash
yum -y update
yum -y install docker
groupadd jenkins
useradd -g jenkins -d /var/lib/jenkins jenkins
usermod -aG dockerroot jenkins
systemctl enable docker
systemctl start docker
docker pull jenkinsci/blueocean
docker run -d -p 8080:8080 jenkinsci/blueocean
systemctl stop firewalld
systemctl disable firewalld
