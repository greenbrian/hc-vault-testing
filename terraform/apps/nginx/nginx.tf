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

  iam_instance_profile = "${aws_iam_instance_profile.consul-nginx.id}"

  user_data = "${data.template_file.nginx-setup.rendered}"
}

data "template_file" "nginx-setup" {
  template = "${file("${path.module}/nginx.tpl")}"
}

resource "aws_iam_role" "consul-nginx" {
  name               = "consul-nginx-self-assemble"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "consul-nginx" {
  name   = "SelfAssembly"
  role   = "${aws_iam_role.consul-nginx.id}"
  policy = "${data.aws_iam_policy_document.consul-nginx.json}"
}

resource "aws_iam_instance_profile" "consul-nginx" {
  name = "consul-nginx"
  role = "${aws_iam_role.consul-nginx.id}"
}
