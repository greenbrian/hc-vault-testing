output "subnet_id" {
  value = "${aws_subnet.hcvt.id}"
}

output "hcvt_sg_id" {
  value = "${aws_security_group.hcvt.id}"
}
