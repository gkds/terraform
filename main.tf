terraform {
    required_version = ">= 0.12"
    backend "s3" {
        bucket = "myappserverbucket"
        key = "myapp/state.tfstate"
        region = "eu-west-3"
    }
}

provider "aws" {

    region = "eu-west-3"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = var.vpc_cidr_block
 
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}


module "myapp-server" {
    source = "./modules/webserver"
    vpc_id = module.vpc.vpc_id
    my_ip = var.my_ip
    env_prefix = var.env_prefix
    image_name = var.image_name
    public_key_location = var.public_key_location
	private_key_location= var.private_key_location
    instance_type = var.instance_type
    
    avail_zones = var.avail_zones
	subnets_count = var.subnets_count

}