# Create an EC2 Auto Scaling Group - web
resource "aws_autoscaling_group" "three-tier-web-asg" {
  name                = "three-tier-web-asg"
  vpc_zone_identifier = [aws_subnet.three-tier-pub-sub-1.id, aws_subnet.three-tier-pub-sub-2.id]
  min_size            = 2
  max_size            = 3
  desired_capacity    = 2
  launch_template {
    id      = aws_launch_template.three-tier-web-lconfig.id
    version = "$Latest"
  }
  depends_on = [aws_launch_template.three-tier-web-lconfig]
}

# Create an EC2 Auto Scaling Group - app
resource "aws_autoscaling_group" "three-tier-app-asg" {
  name                = "three-tier-app-asg"
  vpc_zone_identifier = [aws_subnet.three-tier-pvt-sub-1.id, aws_subnet.three-tier-pvt-sub-2.id]
  min_size            = 2
  max_size            = 3
  desired_capacity    = 2
  launch_template {
    id      = aws_launch_template.three-tier-app-lconfig.id
    version = "$Latest"
  }
  depends_on = [aws_launch_template.three-tier-app-lconfig]
}

###################################################################################################################################

# Create a launch configuration for the EC2 instances
resource "aws_launch_template" "three-tier-web-lconfig" {
  name_prefix            = "three-tier-web-lconfig"
  image_id               = "ami-021e165d8c4ff761d"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.autoscaling-sg-web.id]
  key_name               = "three-tier-web-asg-kp"
  user_data = base64encode(<<-EOF
                                #!/bin/bash

                                # Update the system
                                sudo yum -y update

                                # Install Apache web server
                                sudo yum -y install httpd

                                # Start Apache web server
                                sudo systemctl start httpd.service

                                # Enable Apache to start at boot
                                sudo systemctl enable httpd.service

                                # Create index.html file with your custom HTML
                                sudo echo '
                                <!DOCTYPE html>
                                <html lang="en">
                                    <head>
                                        <meta charset="utf-8" />
                                        <meta name="viewport" content="width=device-width, initial-scale=1" />

                                        <title>A Basic HTML5 Template</title>

                                        <link rel="preconnect" href="https://fonts.googleapis.com" />
                                        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
                                        <link
                                            href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700;800&display=swap"
                                            rel="stylesheet"
                                        />

                                        <link rel="stylesheet" href="css/styles.css?v=1.0" />
                                    </head>

                                    <body>
                                        <div class="wrapper">
                                            <div class="container">
                                                <h1>Welcome! An Apache web server has been started successfully.</h1>
                                                <p>Replace this with your own index.html file in /var/www/html.</p>
                                            </div>
                                        </div>
                                    </body>
                                </html>

                                <style>
                                    body {
                                        background-color: #34333d;
                                        display: flex;
                                        align-items: center;
                                        justify-content: center;
                                        font-family: Inter;
                                        padding-top: 128px;
                                    }

                                    .container {
                                        box-sizing: border-box;
                                        width: 741px;
                                        height: 449px;
                                        display: flex;
                                        flex-direction: column;
                                        justify-content: center;
                                        align-items: flex-start;
                                        padding: 48px 48px 48px 48px;
                                        box-shadow: 0px 1px 32px 11px rgba(38, 37, 44, 0.49);
                                        background-color: #5d5b6b;
                                        overflow: hidden;
                                        align-content: flex-start;
                                        flex-wrap: nowrap;
                                        gap: 24;
                                        border-radius: 24px;
                                    }

                                    .container h1 {
                                        flex-shrink: 0;
                                        width: 100%;
                                        height: auto; /* 144px */
                                        position: relative;
                                        color: #ffffff;
                                        line-height: 1.2;
                                        font-size: 40px;
                                    }
                                    .container p {
                                        position: relative;
                                        color: #ffffff;
                                        line-height: 1.2;
                                        font-size: 18px;
                                    }
                                </style>
                                ' > /var/www/html/index.html

                                EOF
  )

  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
}

# Create a launch configuration for the EC2 instances
resource "aws_launch_template" "three-tier-app-lconfig" {
  name_prefix            = "three-tier-app-lconfig"
  image_id               = "ami-021e165d8c4ff761d"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.autoscaling-sg-app.id]
  key_name               = "three-tier-app-asg-kp"
  user_data = base64encode(<<-EOF
                                #!/bin/bash

                                sudo yum install mysql -y

                                EOF
  )


  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
}

########################################################################################################################
# Create a Security Group for the ASG
resource "aws_security_group" "autoscaling-sg-web" {
  name        = "autoscaling-sg-web-asg-sg"
  description = "Security group for the ASG"
  vpc_id      = aws_vpc.three-tier-vpc.id


  # Allow inbound traffic on port 22 for SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create a Security Group for the ASG
resource "aws_security_group" "autoscaling-sg-app" {
  name        = "autoscaling-sg-app-asg-sg"
  description = "Security group for the ASG"
  vpc_id      = aws_vpc.three-tier-vpc.id


  # Allow inbound traffic on port 22 for SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
