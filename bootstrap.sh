#!/bin/bash

sudo yum update -y
sudo yum install httpd -y
sudo service httpd start
sudo chkconfig httpd on
echo “Metro College AWS CSA“ > /var/www/html/index.html