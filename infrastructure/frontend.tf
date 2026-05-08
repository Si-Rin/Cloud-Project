// Create the EC2 instance for the frontend
resource "aws_instance" "frontend" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_a.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/userdata/frontend.sh", {
    api_url = var.api_url != "" ? var.api_url : "http://${aws_lb.backend_alb.dns_name}"
  }))

  tags = {
    Name = "frontend-instance"
  }
}

