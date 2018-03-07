provider "aws" {
  region = "us-east-1"
}

provider "atlas" {
  token = "${var.atlas_token}"
}

data "terraform_remote_state" "hcvt_consul_vault" {
  backend = "atlas"

  config {
    name = "briangreen/hcvt-consul-vault"
  }
}

module "haproxy" {
  source     = "./haproxy"
  subnet_id  = "${data.terraform_remote_state.hcvt_consul_vault.subnet_id}"
  hcvt_sg_id = "${data.terraform_remote_state.hcvt_consul_vault.hcvt_sg_id}"
}

module "nginx" {
  source             = "./nginx"
  nginx_server_count = 3
  subnet_id          = "${data.terraform_remote_state.hcvt_consul_vault.subnet_id}"
  hcvt_sg_id         = "${data.terraform_remote_state.hcvt_consul_vault.hcvt_sg_id}"
}
