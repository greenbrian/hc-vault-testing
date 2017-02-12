output "consul_addresses" {
  value = ["${module.consul-vault.consul_addresses}"]
}

output "consul_ui" {
  value = "${module.consul-vault.consul_ui}"
}

output "vault_ui" {
  value = ["${module.consul-vault.vault_ui_addresses}"]
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
