terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "example"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.subnet1_cidr
  availability_zone       = var.az1
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.subnet2_cidr
  availability_zone = var.az1

  tags = {
    Name = "Subnet2"
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.subnet3_cidr
  availability_zone       = var.az2
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet3"
  }
}

resource "aws_subnet" "subnet4" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.subnet4_cidr
  availability_zone = var.az2

  tags = {
    Name = "Subnet4"
  }
}

resource "aws_route_table_association" "subnet1association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.publicrt.id
}

resource "aws_route_table_association" "subnet3association" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.publicrt.id
}

resource "aws_eip" "NATEIP" {
  domain = "vpc"
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.NATEIP.id
  subnet_id     = aws_subnet.subnet1.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.myigw]
}


resource "aws_route_table" "privatert" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "example"
  }
}


resource "aws_route_table_association" "subnet2association" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.privatert.id
}

resource "aws_route_table_association" "subnet4association" {
  subnet_id      = aws_subnet.subnet4.id
  route_table_id = aws_route_table.privatert.id
}


resource "aws_security_group" "ec2_sg" {
  name        = "CustomPublicEC2SG"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow_SSH"
  }
}

resource "aws_security_group_rule" "allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2_sg.id
}

resource "aws_key_pair" "ec2KeyPair" {
  key_name   = "HarunKP-ParisNew"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+GE6CfKKUMU8ooEnomrmWuJ2DUkwF+LVG37AcIa/+AMhO654kwY4AD50FPS+WnRFLnNjyCF2Uah7dQrVYUXNr19kOb6QQ8RO/+pGcU3fpyWZvP3p1I1Z2mztyKhBxQIW6k6g51Fvww/VaIkmW2OGB74Y/ODVhI+6Fyzx39JnRWH8xeofYYhpKjiV7gVjbXsgn3WFdacTB0JlxAwE/pHiWK47GNiReOeOaOQaTnHK/7dKeRRZgXMJiib3A9xP8PomQFqRteqg/r0aKTXPRmi4Kh+GAUfes/ldlro0mLQELGpuy3U7KYxQdc85IAl/htZIVa03kIi0qWad1/IIP47VF ec2-user@ip-172-31-25-240.eu-west-3.compute.internal"
}


resource "aws_instance" "publicec2" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = aws_key_pair.ec2KeyPair.id
  security_groups = [aws_security_group.ec2_sg.id]
  subnet_id       = aws_subnet.subnet1.id

  tags = {
    Name = "PublicEC2"
  }
}

resource "aws_instance" "privatec2" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = aws_key_pair.ec2KeyPair.id
  security_groups = [aws_security_group.ec2_sg.id]
  subnet_id       = aws_subnet.subnet2.id

  tags = {
    Name = "PrivateEC2"
  }
}


resource "aws_security_group" "alb_sg" {
  name        = "CustomPublicALBSG"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow_SSH"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "CustomRDSSG"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Allow_SSH"
  }
}

resource "aws_lb_target_group" "webalbtg" {
  name     = "webalbtg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id
}

# resource "aws_lb_target_group_attachment" "test" {
#   target_group_arn = aws_lb_target_group.webalbtg.arn
#   target_id        = aws_instance.privatec2.id
#   port             = 80
# }

resource "aws_lb" "webalb" {
  name               = "webalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet3.id]

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.webalb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webalbtg.arn
  }
}


resource "aws_launch_template" "asgLaunchTemplate" {
  name = "MyASGLaunch-Template"

  image_id               = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ec2KeyPair.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = filebase64("${path.module}/bootstrap.sh")
}


resource "aws_autoscaling_group" "myasg" {
  desired_capacity    = 2
  max_size            = 10
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.webalbtg.arn]
  vpc_zone_identifier = [aws_subnet.subnet2.id, aws_subnet.subnet4.id]

  launch_template {
    id      = aws_launch_template.asgLaunchTemplate.id
    version = "$Latest"
  }
}


resource "aws_db_subnet_group" "rdssubnetgroup" {
  name       = "rdssubnetgroup"
  subnet_ids = [aws_subnet.subnet2.id, aws_subnet.subnet3.id]

  tags = {
    Name = "My DB subnet group"
  }
}

# resource "aws_db_instance" "myrds" {
#   allocated_storage      = 20
#   db_name                = "metrodb"
#   engine                 = "mysql"
#   engine_version         = "5.7"
#   instance_class         = var.db_instance_type
#   username               = "admin"
#   password               = "foobarbaz"
#   parameter_group_name   = "default.mysql5.7"
#   skip_final_snapshot    = true
#   db_subnet_group_name   = aws_db_subnet_group.rdssubnetgroup.id
#   multi_az               = true
#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
# }