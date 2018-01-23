variable "user" {}
variable "priv_key" {}
variable "primary_consul" {}
variable "subnet_id" {}
variable "hcvt_sg_id" {}

data aws_ami "consul-vault" {
  most_recent = true
  owners      = ["self"]
  name_regex  = "ubuntu-16-haproxy*"
}

resource "aws_instance" "haproxy" {
  ami                    = "${data.aws_ami.haproxy.id}"
  instance_type          = "t2.micro"
  count                  = "1"
  subnet_id              = "${var.subnet_id}"
  vpc_security_group_ids = ["${var.hcvt_sg_id}"]

  tags = {
    env = "hcvt-demo"
  }

  connection {
    user        = "${var.user}"
    private_key = "${var.priv_key}"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.primary_consul} > /tmp/consul-server-addr",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/scripts/install.sh",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl enable consul.service",
      "sudo systemctl start consul",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl enable consul-template.service",
      "sudo systemctl start consul-template",
    ]
  }
}
