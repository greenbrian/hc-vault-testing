variable "atlas_token" {}

output "nginx_addresses" {
  value = "${module.nginx.nginx_addresses}"
}

output "ngninx_openssl_check" {
  value = "${module.nginx.nginx_cert_check}"
}

output "haproxy_address" {
  value = "${module.haproxy.haproxy_address}"
}

output "haproxy_stats" {
  value = "${module.haproxy.haproxy_stats}"
}

output "haproxy_web_frontend" {
  value = "${module.haproxy.haproxy_web_frontend}"
}

output "haproxy_vault_frontend" {
  value = "${module.haproxy.haproxy_vault_frontend}"
}

output "secrets_page" {
  value = "${module.haproxy.haproxy_web_frontend_secrets}"
}
