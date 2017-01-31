variable "user" {}
variable "bg_priv_key" {}
variable "consul_server_count" {
  description = "Number of Consul servers to launch"
  default     = "3"
}
