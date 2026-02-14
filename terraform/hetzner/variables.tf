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
  default     = "cx22"  # 2 vCPU, 4GB RAM, 40GB - €4.35/month
  # Options: cx11 (€3.29), cx22 (€4.35), cx32 (€7.69), cx42 (€14.49)
  # ARM options: cax11 (€3.29), cax21 (€5.49), cax31 (€8.99)
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

