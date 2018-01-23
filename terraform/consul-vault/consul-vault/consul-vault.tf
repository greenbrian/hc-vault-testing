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
  count                  = "3"
  subnet_id              = "${var.subnet_id}"
  vpc_security_group_ids = ["${var.hcvt_sg_id}"]

  iam_instance_profile = "${aws_iam_instance_profile.consul-vault.id}"

  tags = {
    env = "hcvt-demo"
  }

  user_data = "${data.template_file.vault-setup.rendered}"
}

data "template_file" "vault-setup" {
  template = "${file("${path.module}/scripts/vault-setup.tpl")}"
}

resource "aws_iam_role" "consul-vault" {
  name               = "consul-vault-self-assemble"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "consul-vault" {
  name   = "SelfAssembly"
  role   = "${aws_iam_role.consul-vault.id}"
  policy = "${data.aws_iam_policy_document.consul-vault.json}"
}

resource "aws_iam_instance_profile" "consul-vault" {
  name = "consul-vault"
  role = "${aws_iam_role.consul-vault.id}"
}
