#!/bin/bash
yum update -y
yum install httpd -y
echo "Web Server: ${count}" >> /var/www/html/index.html
service httpd start
chkconfig httpd on
