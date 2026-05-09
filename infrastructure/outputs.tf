// Outputs for the frontend IP, ALB DNS, and RDS endpoint

// Output the public IP of the frontend EC2 instance
output "frontend_ip" {
  value = aws_instance.frontend.public_ip
}

// Output the endpoint of the RDS database instance
output "rds_endpoint" {
  value = aws_db_instance.db.address
}

//Output the pair key name for the EC2 instances
output "key_pair_name" {
  value = var.key_name
}

//Output the Load Balancer DNS name for the backend ALB
output "backend_alb_dns" {
  value = aws_lb.backend_alb.dns_name
}