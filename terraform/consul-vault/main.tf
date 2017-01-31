provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "./network"
}

module "consul-vault" {
  source              = "./consul-vault"
  user                = "${var.user}"
  priv_key            = "${var.bg_priv_key}"
  consul_server_count = 3
  subnet_id           = "${module.network.subnet_id}"
  hcvt_sg_id          = "${module.network.hcvt_sg_id}"
}
