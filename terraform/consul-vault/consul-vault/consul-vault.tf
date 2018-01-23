variable "user" {}
variable "priv_key" {}
variable "consul_server_count" {}
variable "subnet_id" {}
variable "hcvt_sg_id" {}

data aws_ami "consul-vault" {
  most_recent = true
  owners      = ["self"]
  name_regex  = "ubuntu-16-consul-vault*"
}

resource "aws_instance" "consul-vault" {
  ami                    = "${data.aws_ami.consul-vault.id}"
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
      "echo /tmp/vault_init_and_unseal.sh | at now + 4 min",
    ]
  }
}
