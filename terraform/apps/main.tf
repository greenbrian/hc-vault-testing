provider "aws" {
  region = "us-east-1"
}


data "terraform_remote_state" "hcvt_consul_vault" {
  backend = "atlas"
  config {
    name = "bgreen/hcvt_consul_vault"
    access_token = "$"
  }
}

module "haproxy" {
  source         = "./haproxy"
  user           = "${var.user}"
  key_path       = "${var.bg_priv_key}"
  primary_consul = "${terraform_remote_state.hcvt_consul_vault.output.primary_consul}"
  subnet_id      = "${terraform_remote_state.hcvt_consul_vault.output.subnet_id}"
  hcvt_sg_id     = "${terraform_remote_state.hcvt_consul_vault.output.hcvt_sg_id}"
}

module "nginx" {
  source             = "./nginx"
  user               = "${var.user}"
  priv_key           = "${var.bg_priv_key}"
  nginx_server_count = 2
  primary_consul     = "${terraform_remote_state.hcvt_consul_vault.output.primary_consul}"
  subnet_id          = "${terraform_remote_state.hcvt_consul_vault.output.subnet_id}"
  hcvt_sg_id         = "${terraform_remote_state.hcvt_consul_vault.output.hcvt_sg_id}"
}
