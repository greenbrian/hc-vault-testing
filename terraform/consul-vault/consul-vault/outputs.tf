output "consul_addresses" {
  value = "${formatlist("ssh://%s", aws_instance.consul-vault.*.public_dns)}"
}

output "consul_ui" {
  value = "http://${aws_instance.consul-vault.0.public_dns}:8500/ui/"
}

output "vault_ui_addresses" {
  value = "${formatlist("http://%s:8200/ui/", aws_instance.consul-vault.*.public_dns)}"
}

output "primary_consul" {
  value = "${aws_instance.consul-vault.0.private_dns}"
}
