#!/bin/bash
echo '>>> == Starting to Deploy...'
sudo yum update -y && sudo yum install -y docker

sudo usermod -aG docker ec2-user

wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
sudo chmod -v +x /usr/local/bin/docker-compose

sudo systemctl start docker

docker-compose -f /home/ec2-user/docker-compose.yml up -d
echo '>>> == Starting new container via docker-compose'