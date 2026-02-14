# -----------------------------------------------------------------------------
# Hetzner Cloud Configuration
# -----------------------------------------------------------------------------

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "fsn1"  # Falkenstein, Germany (cheapest)
  # Other options: nbg1 (Nuremberg), hel1 (Helsinki), ash (Ashburn, US)
}

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------

variable "projects" {
  description = "List of project names to deploy"
  type        = list(string)
  default     = ["default"]
}

# -----------------------------------------------------------------------------
# Server Configuration
# -----------------------------------------------------------------------------

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cx23"  # 2 vCPU, 4GB RAM, 40GB
  # Options: cx23 (2c/4GB), cx33 (4c/8GB), cx43 (8c/16GB), cx53 (16c/32GB)
  # ARM options: cax11 (2c/4GB), cax21 (4c/8GB), cax31 (8c/16GB)
}

variable "image" {
  description = "OS image"
  type        = string
  default     = "ubuntu-24.04"
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "network_cidr" {
  description = "Private network CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

# -----------------------------------------------------------------------------
# SSH Configuration
# -----------------------------------------------------------------------------

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key (for provisioning)"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_key_name" {
  description = "Name for the SSH key in Hetzner"
  type        = string
  default     = "claude-dev"
}

# -----------------------------------------------------------------------------
# Firewall Configuration
# -----------------------------------------------------------------------------

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_app_cidrs" {
  description = "CIDR blocks allowed to access the app (port 3001)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# -----------------------------------------------------------------------------
# Application Configuration
# -----------------------------------------------------------------------------

variable "git_repo_url" {
  description = "Git repository URL for claude-dev"
  type        = string
  default     = "https://github.com/your-org/claude-dev.git"
}

