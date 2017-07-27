output "nginx_addresses" {
  value = "${formatlist("ssh://%s", aws_instance.nginx.*.public_dns)}"
}

output "nginx_cert_check" {
  value = "${formatlist("echo | openssl s_client -showcerts -servername foo.example.com -connect %s:443 2>/dev/null | openssl x509 -inform pem -noout -text | head -n 14", aws_instance.nginx.*.public_dns)}"
}
