## Internet gateway

resource "aws_internet_gateway" "internet_gateway" {

 vpc_id = var.vpc_id
  tags = {
    Name = "internetGW"
  }
}

## SUBNETS
resource "aws_subnet" "vpc_public_subnet" {
  vpc_id = var.vpc_id
  count = length(var.subnets_count)
  availability_zone = element(var.avail_zones, count.index)
  cidr_block = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-sub-${element(var.avail_zones, count.index)}"
  }
}

resource "aws_subnet" "vpc_private_subnet" {
  count = length(var.subnets_count)
  availability_zone = element(var.avail_zones, count.index)
  cidr_block = "10.0.${count.index + 2}.0/24"
  vpc_id = var.vpc_id

  tags = {
    Name = "pri-sub-${element(var.avail_zones, count.index)}"
  }
}

## ROUTE TABLE CONFIG

resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "public-route-tbl"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  count = length(var.subnets_count)
  subnet_id = element(aws_subnet.vpc_public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

## NAT gateway for private subnets_count

resource "aws_eip" "elasticIP" {
  count = length(var.subnets_count)
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  count = length(var.subnets_count)
  allocation_id = element(aws_eip.elasticIP.*.id, count.index)
  subnet_id = element(aws_subnet.vpc_public_subnet.*.id, count.index)

  tags = {
    Name = "nat-GTW-${count.index}"
  }
}

resource "aws_route_table" "private_route_table" {
  count = length(var.subnets_count)
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name = "private-route-tbl"
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  count = length(var.subnets_count)
  subnet_id = element(aws_subnet.vpc_private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id,
  count.index)
}

#### SECURITY groups
resource "aws_security_group" "my-sg" {
    vpc_id = var.vpc_id
    name = "myapp-sg"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	
	 ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
        Name = "${var.env_prefix}-sg"
    }
}

##  Add an ELB LaodBalancer for front instances
# Create a new load balancer

resource "aws_elb" "myElb" {
  name               = "myapp-elb"
  availability_zones = var.avail_zones
  count = length(var.subnets_count)

  access_logs {
    bucket        = "elb"
    bucket_prefix = "myapp"
    interval      = 60
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    #ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = [aws_instance.cabinetmed-svr[count.index].id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "myapp-elb"
  }
}

## ec2 INSTANCE TYPE

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = [var.image_name]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_location)
}

resource "aws_instance" "cabinetmed-svr" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

	count = length(var.subnets_count)
    subnet_id = element(aws_subnet.vpc_public_subnet.*.id, count.index)
    security_groups = [aws_security_group.my-sg.id]
    #availability_zone = var.avail_zones[0]

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name
	
	provisioner "file" {
        source      = "docker-compose.yml"
        destination = "/home/ec2-user/docker-compose.yml"
       
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file(var.private_key_location)}"
      host        = "${self.public_ip}"
    }
   }

    user_data = file("entry-script.sh")

    tags = {
        Name = "${var.env_prefix}-cabinetmed-svr-${count.index}"
    }
}
