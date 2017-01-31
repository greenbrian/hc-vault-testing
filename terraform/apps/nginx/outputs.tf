output "nginx_addresses" {
  value = "${formatlist("ssh://%s", aws_instance.nginx.*.public_dns)}"
}
