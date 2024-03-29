# configure aws provider to establish a secure connection between terraform and aws
provider "aws" {
  region  = var.region
  profile = "terraform-user"
}

# create vpc
module vpc {
  source                      = "./modules/vpc"
  region                      = var.region
  project_name                = var.project_name
  vpc_cidr                    = var.vpc_cidr
  public_subnet_az1_cidr      = var.public_subnet_az1_cidr
  private_subnet_az1_cidr     = var.private_subnet_az1_cidr
  public_subnet_az2_cidr      = var.public_subnet_az2_cidr
  private_subnet_az2_cidr     = var.private_subnet_az2_cidr
}

# create nat-gateway
module nat-gateway {
  source                      = "./modules/nat-gateway"
  public_subnet_az1_id        = module.vpc.public_subnet_az1_id
  internet_gateway            = module.vpc.internet_gateway
  public_subnet_az2_id        = module.vpc.public_subnet_az2_id
  vpc_id                      = module.vpc.vpc_id
  private_subnet_az1_id       = module.vpc.private_subnet_az1_id
  private_subnet_az2_id       = module.vpc.private_subnet_az2_id
}

# create security groups
module security-group {
  source                      = "./modules/security-group"
  vpc_id                      = module.vpc.vpc_id
}

# create acm
module acm {
  source                      = "./modules/acm"
  domain_name                 = var.domain_name
  alternative_name            = var.alternative_name
}

# create application load balancer
module application-load-balancer {
  source                      = "./modules/application-load-balancer"
  project_name                = module.vpc.project_name
  alb_security_group_id       = module.security-group.alb_security_group_id 
  public_subnet_az1_id        = module.vpc.public_subnet_az1_id
  public_subnet_az2_id        = module.vpc.public_subnet_az2_id
  vpc_id                      = module.vpc.vpc_id
  certificate_arn             = module.acm.certificate_arn
}