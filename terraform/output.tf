output "control_plane_ip" {
  value = module.compute.control_private_ip
}

output "agent_ip" {
  value = module.compute.agent_private_ip
}

output "host_ip" {
  value = module.compute.host_public_ip
}