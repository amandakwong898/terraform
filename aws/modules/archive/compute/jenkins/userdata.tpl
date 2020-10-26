#!/bin/bash
yum -y update
yum -y install bind-utils yum-utils nc wget curl java-1.8.0-openjdk-devel net-tools
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
yum -y install jenkins
systemctl stop firewalld
systemctl disable firewalld
systemctl start jenkins
systemctl enable jenkins
