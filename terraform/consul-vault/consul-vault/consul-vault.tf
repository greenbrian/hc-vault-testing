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

data "template_file" "consul_config" {
  count    = "${var.consul_server_count}"
  template = "${path.module}/scripts/consul.sh.tpl"

  lifecycle { create_before_destroy = true }

  vars {
    consul_server_count = "${count}"
    consul_join_address = "${aws_instance.consul-vault.0.private_dns}"
  }
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

  connection {
    user        = "${var.user}"
    private_key = "${var.priv_key}"
  }


  provisioner "remote-exec" {
    inline = [
      "echo ${var.consul_server_count} > /tmp/consul-server-count",
      "echo ${aws_instance.consul-vault.0.private_dns} > /tmp/consul-server-addr",
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
      "sudo systemctl enable vault.service",
      "sudo systemctl start vault",
    ]
  }

  /*  ###################   WARNING    #########################  */
  /* The following steps are not recommended for production usage */
  /* The script will initialize your vault and store the secret   */
  /* keys insecurely and is only used for demonstration purposes  */

  provisioner "file" {
    source      = "${path.module}/scripts/vault_init_and_unseal.sh"
    destination = "/tmp/vault_init_and_unseal.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/vault_init_and_unseal.sh",
      "echo /tmp/vault_init_and_unseal.sh | at now + 1 min",
    ]
  }
}
