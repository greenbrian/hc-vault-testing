provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "./network"
}

module "consul-vault" {
  source     = "./consul-vault"
  user       = "${var.user}"
  subnet_id  = "${module.network.subnet_id}"
  hcvt_sg_id = "${module.network.hcvt_sg_id}"
}
