variable "subnet_id" {}
variable "hcvt_sg_id" {}

data aws_ami "haproxy" {
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

  iam_instance_profile = "${aws_iam_instance_profile.consul-haproxy.id}"
  user_data            = "${data.template_file.haproxy-setup.rendered}"
}

data "template_file" "haproxy-setup" {
  template = "${file("${path.module}/haproxy.tpl")}"
}

resource "aws_iam_role" "consul-haproxy" {
  name               = "consul-haproxy-self-assemble"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "consul-haproxy" {
  name   = "SelfAssembly"
  role   = "${aws_iam_role.consul-haproxy.id}"
  policy = "${data.aws_iam_policy_document.consul-haproxy.json}"
}

resource "aws_iam_instance_profile" "consul-haproxy" {
  name = "consul-haproxy"
  role = "${aws_iam_role.consul-haproxy.id}"
}
