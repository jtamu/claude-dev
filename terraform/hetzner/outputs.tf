output "servers" {
  description = "Server details per project"
  value = {
    for project, server in hcloud_server.claude_dev : project => {
      server_id   = server.id
      ipv4        = server.ipv4_address
      ipv6        = server.ipv6_address
      server_type = server.server_type
      location    = server.location
      webui_url   = "http://${server.ipv4_address}:3001"
    }
  }
}

output "ssh_commands" {
  description = "SSH commands for each server"
  value = {
    for project, server in hcloud_server.claude_dev : project =>
    "ssh -i ${var.ssh_private_key_path} root@${server.ipv4_address}"
  }
}

output "monthly_cost_estimate" {
  description = "Estimated monthly cost"
  value = {
    server_type   = var.server_type
    cost_per_unit = var.server_type == "cx23" ? "€4.35" : var.server_type == "cax11" ? "€3.29" : "varies"
    instances     = length(var.projects)
    total         = "${length(var.projects)} x ${var.server_type}"
  }
}
