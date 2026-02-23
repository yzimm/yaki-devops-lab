variable "host_ip" {
  type    = string
  default = "10.53.118.15" # Make sure this matches your actual current IP
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "k8s_token" {
  type      = string
  sensitive = true
  default   = "" 
}

# Add this new block here:
variable "argocd_admin_password" {
  type      = string
  sensitive = true
}