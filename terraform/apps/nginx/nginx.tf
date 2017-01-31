variable "user" {}
variable "priv_key" {}
variable "primary_consul" {}
variable "nginx_server_count" {}
variable "subnet_id" {}
variable "hcvt_sg_id" {}

data "atlas_artifact" "nginx" {
  name  = "bgreen/hcvt-nginx"
  type  = "amazon.image"
  build = "latest"
}

resource "aws_instance" "nginx" {
  ami                    = "${data.atlas_artifact.nginx.metadata_full.region-us-east-1}"
  instance_type          = "t2.micro"
  count                  = "${var.nginx_server_count}"
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

  provisioner "file" {
    source      = "${path.module}/scripts/secret_page.sh"
    destination = "/tmp/secret_page.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/secret_page.sh",
    ]
  }
}
