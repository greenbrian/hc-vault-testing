provider "aws" {
  region = "us-east-1"
}

provider "atlas" {
  token = "${var.atlas_token}"
}

data "terraform_remote_state" "hcvt_consul_vault" {
  backend = "atlas"

  config {
    name = "briangreen/hcvt-consul-vault-beta"
  }
}

module "haproxy" {
  source         = "./haproxy"
  user           = "${var.user}"
  priv_key       = "${var.bg_priv_key}"
  primary_consul = "${data.terraform_remote_state.hcvt_consul_vault.primary_consul}"
  subnet_id      = "${data.terraform_remote_state.hcvt_consul_vault.subnet_id}"
  hcvt_sg_id     = "${data.terraform_remote_state.hcvt_consul_vault.hcvt_sg_id}"
}

module "nginx" {
  source             = "./nginx"
  user               = "${var.user}"
  priv_key           = "${var.bg_priv_key}"
  nginx_server_count = 4
  primary_consul     = "${data.terraform_remote_state.hcvt_consul_vault.primary_consul}"
  subnet_id          = "${data.terraform_remote_state.hcvt_consul_vault.subnet_id}"
  hcvt_sg_id         = "${data.terraform_remote_state.hcvt_consul_vault.hcvt_sg_id}"
}
