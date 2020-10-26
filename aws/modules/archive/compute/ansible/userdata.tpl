#!/bin/bash
yum update -y
sudo yum -y install wget nc bind-utils unzip
curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py
sudo python get-pip.py
pip install --upgrade pip
pip install --user virtualenv
mkdir ~/venv
virtualenv ~/venv
source ~/venv/bin/activate
echo "source venv/bin/activate" >> ~/.bash_profile
pip install boto
pip install boto3
pip install awscli
pip install -I ansible
pip install credstash
