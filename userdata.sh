#!/bin/bash

# 1. Update the server and install the Apache Web Server and AWS tools
apt-get update -y
apt-get install apache2 -y
apt-get install awscli -y

# 2. Turn on the web server
systemctl start apache2
systemctl enable apache2

# 3. Download your specific files from the S3 bucket into the public web folder
aws s3 cp s3://${bucket_name}/terrastream.html /var/www/html/terrastream.html
aws s3 cp s3://${bucket_name}/video.mp4 /var/www/html/video.mp4

# 4. Restart Apache to make sure everything loads perfectly
systemctl restart apache2