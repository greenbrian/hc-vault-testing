output "consul_addresses" {
  value = ["${module.consul-vault.consul_addresses}"]
}

output "consul_ui" {
  value = "${module.consul-vault.consul_ui}"
}

output "primary_consul" {
  value = "${module.consul-vault.primary_consul}"
}

output "subnet_id" {
  value = "${module.network.subnet_id}"
}

output "hcvt_sg_id" {
  value = "${module.network.hcvt_sg_id}"
}
