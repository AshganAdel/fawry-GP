output "control_private_ip" {
  value = aws_instance.ec2_control.private_ip
}

output "agent_private_ip" {
  value = aws_instance.ec2_agent.private_ip
}

output "host_public_ip" {
  value = aws_instance.host.public_ip
}