variable "user" {}
variable "priv_key" {}
variable "consul_server_count" {}
variable "subnet_id" {}
variable "hcvt_sg_id" {}

data "atlas_artifact" "consul-vault" {
  name  = "bgreen/hcvt-consul-vault"
  type  = "amazon.image"
  build = "latest"
}

resource "aws_instance" "consul-vault" {
  ami                    = "${data.atlas_artifact.consul-vault.metadata_full.region-us-east-1}"
  instance_type          = "t2.micro"
  count                  = "${var.consul_server_count}"
  subnet_id              = "${var.subnet_id}"
  vpc_security_group_ids = ["${var.hcvt_sg_id}"]

  tags = {
    env = "hcvt-demo"
  }

  user_data = "${data.template_file.vault-setup.rendered}"
}

data "template_file" "vault-setup" {
  template = "${file("${path.module}/scripts/vault-setup.tpl")}"

  vars = {
    consul_server_count = "${var.consul_server_count}"
    consul_server_addr  = "${aws_instance.consul-vault.0.private_dns}"
  }
}
