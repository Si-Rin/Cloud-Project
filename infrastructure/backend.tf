// Launch the EC2 template with the specified configuration
resource "aws_launch_template" "backend_lt" {
  name_prefix   = "backend-template"
  image_id      = var.ami_id
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data = base64encode(templatefile("${path.module}/userdata/backend.sh", {
    db_host = aws_db_instance.db.address
    db_user = var.db_username
    db_pass = var.db_password
    db_name = var.db_name
  }))
}

// Target group for the backend instances
resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/"
  }
}

// Application Load Balancer (ALB) for the backend
resource "aws_lb" "backend_alb" {
  name               = "backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

// Listener for the ALB to forward traffic to the backend target group
resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn // arn : Amazon Resource Name
  }
}

// Auto Scaling Group for the backend instances
resource "aws_autoscaling_group" "backend_asg" {
  name             = "backend-asg"
  max_size         = 4
  min_size         = 2
  desired_capacity = 2
  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }
  vpc_zone_identifier       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  target_group_arns         = [aws_lb_target_group.backend_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
}