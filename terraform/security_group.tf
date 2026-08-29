resource "aws_security_group" "vpce" {
  name        = "rails-aws-sre-lab-vpce-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTPS from ECS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = {
    Name = "rails-aws-sre-lab-vpce-sg"
  }
}

resource "aws_security_group" "ecs" {
  name        = "rails-aws-sre-lab-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rails-aws-sre-lab-ecs-sg"
  }
}
