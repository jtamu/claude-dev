terraform {
  required_version = ">= 1.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# -----------------------------------------------------------------------------
# SSH Key
# -----------------------------------------------------------------------------

resource "hcloud_ssh_key" "main" {
  name       = var.ssh_key_name
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# -----------------------------------------------------------------------------
# Firewall
# -----------------------------------------------------------------------------

resource "hcloud_firewall" "main" {
  name = "claude-dev-firewall"

  # SSH
  dynamic "rule" {
    for_each = var.allowed_ssh_cidrs
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "22"
      source_ips = [rule.value]
    }
  }

  # Claude Code WebUI
  dynamic "rule" {
    for_each = var.allowed_app_cidrs
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "3001"
      source_ips = [rule.value]
    }
  }

  # ICMP
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Outbound
  rule {
    direction       = "out"
    protocol        = "tcp"
    port            = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction       = "out"
    protocol        = "udp"
    port            = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction       = "out"
    protocol        = "icmp"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }
}

# -----------------------------------------------------------------------------
# Servers (one per project)
# -----------------------------------------------------------------------------

resource "hcloud_server" "claude_dev" {
  for_each = toset(var.projects)

  name        = "claude-dev-${each.key}"
  server_type = var.server_type
  image       = var.image
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.main.id]
  firewall_ids = [hcloud_firewall.main.id]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    project_name = each.key
    git_repo_url = var.git_repo_url
  })

  labels = {
    project    = each.key
    managed_by = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Copy credentials to servers
# -----------------------------------------------------------------------------

resource "null_resource" "copy_credentials" {
  for_each = hcloud_server.claude_dev

  triggers = {
    server_id = each.value.id
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(pathexpand(var.ssh_private_key_path))
    host        = each.value.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.claude",
      "chmod 700 /root/.claude"
    ]
  }

  provisioner "file" {
    source      = pathexpand(var.claude_credentials_file)
    destination = "/root/.claude/.credentials.json"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /root/.claude/.credentials.json",
      "echo 'Credentials copied. Waiting for Docker setup...'",
      "while ! docker info >/dev/null 2>&1; do sleep 5; done",
      "echo 'Docker is ready. Injecting credentials into volume...'",
      "/opt/claude-dev/setup-credentials.sh",
      "echo 'Starting service...'",
      "systemctl start claude-dev"
    ]
  }
}
