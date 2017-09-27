variable "subnet_id" {}
variable "hcvt_sg_id" {}

data "atlas_artifact" "haproxy" {
  name  = "bgreen/hcvt-haproxy"
  type  = "amazon.image"
  build = "latest"
}

resource "aws_instance" "haproxy" {
  ami                    = "${data.atlas_artifact.haproxy.metadata_full.region-us-east-1}"
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
  name               = "consul-self-assemble"
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
