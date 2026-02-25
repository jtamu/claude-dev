terraform {
  required_version = ">= 1.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
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

  # HTTP (Let's Encrypt ACME challenge — must be open to all)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS
  dynamic "rule" {
    for_each = var.allowed_app_cidrs
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "443"
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

  name         = "claude-dev-${each.key}"
  server_type  = var.server_type
  image        = var.image
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.main.id]
  firewall_ids = [hcloud_firewall.main.id]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    project_name  = each.key
    git_repo_url  = var.git_repo_url
    domain        = "${each.key}.${var.domain}"
    certbot_email = var.certbot_email
  })

  labels = {
    project    = each.key
    managed_by = "terraform"
  }
}

# -----------------------------------------------------------------------------
# DNS Records (Cloudflare)
# -----------------------------------------------------------------------------

resource "cloudflare_record" "claude_dev" {
  for_each = hcloud_server.claude_dev

  zone_id = var.cloudflare_zone_id
  name    = each.key
  content = each.value.ipv4_address
  type    = "A"
  ttl     = 300
  proxied = false
}

