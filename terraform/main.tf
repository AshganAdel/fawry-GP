module "compute" {
  source = "./modules/compute"
  public_subnet_id = module.network.public_subnet_id
  vpc_id = module.network.vpc_id
  private_subnet_id = module.network.private_subnet_id
}

module "network" {
  source = "./modules/network"  
  cidr_block = var.cidr_block
  cidr_block_private_subnet = var.cidr_block_private_subnet
}

