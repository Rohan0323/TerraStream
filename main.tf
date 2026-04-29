resource "random_id" "generator" {
  byte_length = 2
}

#VPC Creation for video streaming
resource "aws_vpc" "VPC-VIDEO-STREAMER" {
 cidr_block = var.vpc-cidr
 tags = {
   "Name" = "VPC-VIDEO-STREAMER-${random_id.generator.hex}"
 }
}

output "vpc" {
  value = aws_vpc.VPC-VIDEO-STREAMER.tags.Name
}


#Subnet 1 Creation
resource "aws_subnet" "sub-1-public" {
  vpc_id = aws_vpc.VPC-VIDEO-STREAMER.id  
  cidr_block = var.sub-1-public-cidr
  availability_zone = var.sub-1-public-az
  tags = {
    "Name" = "sub-1-public-${random_id.generator.hex}"
  }
}

output "sub_1" {
  value = aws_subnet.sub-1-public.tags.Name
}

#Subnet 2 creation
resource "aws_subnet" "sub-2-public" {
  vpc_id = aws_vpc.VPC-VIDEO-STREAMER.id
  cidr_block = var.sub-2-public-cidr
  availability_zone = var.sub-2-public-az
  tags = {
    "Name" = "sub-2-public-${random_id.generator.hex}"
  }
}

output "sub_2" {
  value = aws_subnet.sub-2-public.tags.Name
}


#Internet Gateway Creation
resource "aws_internet_gateway" "IGW-VIDEO-STREAMER" {
  vpc_id = aws_vpc.VPC-VIDEO-STREAMER.id
  tags = {
    "Name" = "IGW-VIDEO-STREAMER-${random_id.generator.hex}"
  }
}

output "IGW" {
  value = aws_internet_gateway.IGW-VIDEO-STREAMER.tags.Name
}


#Route Table Creation
resource "aws_route_table" "CRT-VIDEO-STREAMER" {
  vpc_id = aws_vpc.VPC-VIDEO-STREAMER.id
  tags = {
    "Name" = "CRT-VIDEO-STREAMER-${random_id.generator.hex}"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW-VIDEO-STREAMER.id
  }
}

output "CRT" {
  value = aws_route_table.CRT-VIDEO-STREAMER.tags.Name
}


#Route Table subnet association
resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.sub-1-public.id
  route_table_id = aws_route_table.CRT-VIDEO-STREAMER.id
}
resource "aws_route_table_association" "b" {
  subnet_id = aws_subnet.sub-2-public.id
  route_table_id = aws_route_table.CRT-VIDEO-STREAMER.id
}


#Security Group Creation for Load Balancer
resource "aws_security_group" "ALB-SG-VIDEO-STREAMER" {
  tags = {
    "Name"= "ALB-SG-VIDEO-STREAMER-${random_id.generator.hex}"
  }
  vpc_id = aws_vpc.VPC-VIDEO-STREAMER.id

#ingress controls who is allowed to visit the video stream
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


#egress controls what the LB is allowed to do when sending the traffic out
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "SG_ALB" {
  value = aws_security_group.ALB-SG-VIDEO-STREAMER.tags.Name
}


#Security group creation for EC2 which allows traffic from ALB
resource "aws_security_group" "EC2-SG-VIDEO-STREAMER" {
  tags = {
    "Name" = "EC2-SG-VIDEO-STREAMER-${random_id.generator.hex}"
  }
  vpc_id = aws_vpc.VPC-VIDEO-STREAMER.id


#Listens for unencrypted web traffic(HTTP)
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"

#CIDR block is missing because it only allows traffic from ALB only
    security_groups = [aws_security_group.ALB-SG-VIDEO-STREAMER.id]
  }


#this allows EC2 to send traffic out anywhere
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
output "SG_EC2" {
  value = aws_security_group.EC2-SG-VIDEO-STREAMER.tags.Name
}


#IAM role for EC2(only) to read from s3
resource "aws_iam_role" "EC2-S3-ROLE-VIDEO-STREAMER" {
  tags = {
    "Name" = "EC2-S3-READONLY-ROLE-${random_id.generator.hex}"
  }


#It is a trust policy where we are  giving EC2 only to access the S3 bucket no other than EC2
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com"}
    }]
  })
}
output "EC2-role" {
  value = aws_iam_role.EC2-S3-ROLE-VIDEO-STREAMER.tags.Name
}

#Attach ReadOnly policy to EC2 
resource "aws_iam_role_policy_attachment" "S3-READONLY-ATTACH" {
  role = aws_iam_role.EC2-S3-ROLE-VIDEO-STREAMER.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

#Attaches S3 read-only permissions to the IAM role and creates an instance profile wrapper for EC2 to use.
resource "aws_iam_instance_profile" "S3-INSTANCE-PROFILE" {
  tags = {
    "Name" = "EC2-S3-PROFILE-${random_id.generator.hex}"
  }
  role = aws_iam_role.EC2-S3-ROLE-VIDEO-STREAMER.name
}
output "S3-read-only" {
  value = aws_iam_instance_profile.S3-INSTANCE-PROFILE.tags.Name
}


#S3 bucket creation and file Upload

resource "aws_s3_bucket" "TERRASTREAM-BUCKET" {
  bucket = "terrastream-video-${random_id.generator.hex}"
  force_destroy = true
}

output "bucket_id" {
  value = aws_s3_bucket.TERRASTREAM-BUCKET.id
}
resource "aws_s3_object" "html_file" {
  bucket = aws_s3_bucket.TERRASTREAM-BUCKET.id
  key = "terrastream.html"
  source = "${path.module}/terrastream.html"
  content_type = "text/html"
}
resource "aws_s3_object" "video_mp4" {
  bucket = aws_s3_bucket.TERRASTREAM-BUCKET.id
  key = "video.mp4"
  source = "${path.module}/video.mp4"
  content_type = "video/mp4"
}

#fetch the latest UBUNTU
data "aws_ami" "UBUNTU" {
  most_recent = true
  owners = ["099720109477"] #UBUNTU(Canonical) official owner id
  filter {
    name = "name"
     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "stream-lt" {
  name_prefix = "terrastream-video-${random_id.generator.hex}"
  image_id = data.aws_ami.UBUNTU.id
  instance_type = "t3.micro"

  iam_instance_profile {
    arn = aws_iam_instance_profile.S3-INSTANCE-PROFILE.arn
  }

  
  network_interfaces {
    security_groups = [aws_security_group.EC2-SG-VIDEO-STREAMER.id]
    associate_public_ip_address = true
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh",{
    bucket_name = aws_s3_bucket.TERRASTREAM-BUCKET.id
  }))
  depends_on = [ aws_iam_role_policy_attachment.S3-READONLY-ATTACH ]
}
output "stream-lt" {
  value = aws_launch_template.stream-lt.name_prefix
}

#Creation of Application Load Balancer
resource "aws_lb" "STREAMER-ALB" {
  tags = {
    "Name" = "VIDEO-STREAMER-ALB-${random_id.generator.hex}"
  }
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.ALB-SG-VIDEO-STREAMER.id]
  subnets = [ aws_subnet.sub-1-public.id, aws_subnet.sub-2-public.id ]
}
output "STREAMER-ALB" {
  value = aws_lb.STREAMER-ALB.tags.Name
}

#Creation of Target Group (Where traffic must be sent)
resource "aws_lb_target_group" "STREAMER-TG" {
  tags = {
    "Name" = "-VIDEO-STREAMER-TG-${random_id.generator.hex}"
  }
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.VPC-VIDEO-STREAMER.id

  health_check {
    path = "/terrastream.html"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    interval = 10
  }
}
output "STREAMER-TG" {
  value = aws_lb_target_group.STREAMER-TG.tags.Name
}

#Creates the connection between ALB & TG
resource "aws_lb_listener" "HTTP_LISTENER" {
  load_balancer_arn = aws_lb.STREAMER-ALB.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.STREAMER-TG.arn
  }
}

#Creation of auto scaling groups to add or remove servers according to Load
resource "aws_autoscaling_group" "STREAMER-ASG" {
  name = "VIDEO-STREAMER-ASG-${random_id.generator.hex}"
  vpc_zone_identifier = [aws_subnet.sub-1-public.id, aws_subnet.sub-2-public.id]
  target_group_arns = [aws_lb_target_group.STREAMER-TG.arn]

  min_size = 1
  max_size = 3
  desired_capacity = 1

  launch_template {
    id = aws_launch_template.stream-lt.id
    version = "$Latest"
  }
}

output "aws_autoscaling_group" {
  value = aws_autoscaling_group.STREAMER-ASG.name
}


#Creation of auto scaling policy(triggers when cpu server goes above 60%)
resource "aws_autoscaling_policy" "cpu_scaling"{
  name = "CPU-TRACKING-POLICY-${random_id.generator.hex}"
  policy_type = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.STREAMER-ASG.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

output "aws_autoscaling_policy" {
  value = aws_autoscaling_policy.cpu_scaling.name
}

#output
output "streaming_url" {
  description = "Click this link to watch your TERRASTREAM video!"
  value       = "http://${aws_lb.STREAMER-ALB.dns_name}/terrastream.html"
}