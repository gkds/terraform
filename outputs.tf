output "ec2_public_ip" {
	
    value = module.myapp-server.instance[0].public_ip
}