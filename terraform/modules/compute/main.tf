resource "aws_security_group" "instance" {
  name        = "k3s-security_group"
  description = "Allow SSH, HTTP and k3s ports"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = {
      ssh  = { port = 22, cidrs = ["0.0.0.0/0"], protocol = "tcp"}
      http = { port = 8080, cidrs = ["0.0.0.0/0"], protocol = "tcp" }
      nlb = { port = 80, cidrs = ["0.0.0.0/0"], protocol = "tcp" }
      k3s_api = { port = 6443, cidrs = ["0.0.0.0/0"], protocol = "tcp" }
      nodeport = { port = 30200, cidrs = ["0.0.0.0/0"], protocol = "tcp"}
      nodeport = { port = 30080, cidrs = ["0.0.0.0/0"], protocol = "tcp"}
      kubelet = { port = 10250, cidrs = ["0.0.0.0/0"], protocol = "tcp"}
      Flannel_VXLAN = { port = 8472, cidrs = ["0.0.0.0/0"], protocol = "udp"}
      app = { port = 5002, cidrs = ["0.0.0.0/0"], protocol = "tcp" }
      db = { port = 3306, cidrs = ["0.0.0.0/0"], protocol = "tcp" }
    }
    content {
      description = ingress.key
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidrs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k3s-security_group"
  }
}
resource "aws_instance" "host" {
  ami           = "ami-05f991c49d264708f"
  instance_type = "t3.micro"
  subnet_id = var.public_subnet_id
  key_name = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [ aws_security_group.instance.id ]
  tags = {
    Name = "host"
  }
}
resource "aws_instance" "ec2_control" {
  ami           = "ami-05f991c49d264708f"
  instance_type = "t3.small"
  subnet_id = var.private_subnet_id
  key_name = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [ aws_security_group.instance.id ]
  tags = {
    Name = "control_plane"
  }
}

resource "aws_instance" "ec2_agent" {
  ami           = "ami-05f991c49d264708f"
  instance_type = "t3.micro"
  subnet_id = var.private_subnet_id
  key_name = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [ aws_security_group.instance.id ]
  tags = {
    Name = "agent"
  }
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "ec2_key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.ec2_key.private_key_pem
  filename = "/home/ashgan/.ssh/ec2_key.pem"
  file_permission = "0400"
}

resource "aws_lb" "nlb" {
  name               = "k3s-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            =  [ var.public_subnet_id ]
}

resource "aws_lb_target_group" "k3s_http" {
  name     = "k3s-http"
  port     = 30080
  protocol = "TCP"
  vpc_id   = var.vpc_id
  target_type = "instance"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_http.arn
  }
}

resource "aws_lb_target_group_attachment" "k3s_nodes" {
  target_group_arn = aws_lb_target_group.k3s_http.arn
  target_id        = aws_instance.ec2_agent.id
  port             = 30080
}

