variable "user" {}

variable "consul_server_count" {
  description = "Number of Consul servers to launch"
  default     = "3"
}
