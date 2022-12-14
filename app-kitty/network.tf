
data "aws_vpc" "default" { 
    filter {
        name = "is-default"
        values = [true]
    }
}

data "aws_subnet" "default" { 
    vpc_id = data.aws_vpc.default.id
    #availability_zone = "us-east-1f"
    availability_zone = data.aws_availability_zone.primary.id
}

### Create VPC with GW-NAT routed through main route-table
resource "aws_vpc" "kitty-app" { 
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "app-vpc"
    }
}

resource "aws_route_table" "kitty-main" {
    vpc_id = aws_vpc.kitty-app.id
    tags = {
        Name = "Private Route Table" # "app-main-route"
    }
    route = []
}

resource "aws_route" "kitty-main" {
    route_table_id = aws_route_table.kitty-main.id

    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
}

resource "aws_main_route_table_association" "main" {
    route_table_id = aws_route_table.kitty-main.id
    vpc_id = aws_vpc.kitty-app.id
}

resource "aws_eip" "gw" {
  network_border_group = data.aws_availability_zone.primary.region
}

resource "aws_nat_gateway" "gw" {
    allocation_id = aws_eip.gw.id
    subnet_id = aws_subnet.kitty-public.id

    tags = {
        Name = "GW for private snet"
    }
}


### Create Subnet with entry inet gw 

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.kitty-app.id

    tags = {
        Name = "app-igw"
    }
}

## VPC Public route 
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.kitty-app.id
    tags = {
        Name = "Public Route Table"
    }
    route = []
}

### VPC Public Route - default gw
resource "aws_route" "inet" {
    route_table_id = aws_route_table.public.id

    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
}


### VPC Subnet 1 - public
resource "aws_subnet" "kitty-public" { 
    vpc_id = aws_vpc.kitty-app.id
    #availability_zone = "us-east-1f"
    availability_zone = data.aws_availability_zone.primary.id
    cidr_block = "10.0.1.0/24"

    enable_resource_name_dns_a_record_on_launch = true

    tags = {
        Name = "Public Subnet 1"
    }
}

### VPC Public Route - subnet-1 association
resource "aws_route_table_association" "public" {
    route_table_id = aws_route_table.public.id
    subnet_id = aws_subnet.kitty-public.id
}

### VPC Subnet 2 - public standby
resource "aws_subnet" "kitty-public-standby" { 
    vpc_id = aws_vpc.kitty-app.id
    #availability_zone = "us-east-1f"
    availability_zone = data.aws_availability_zone.secondary.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    tags = {
        Name = "Public Subnet 1 Standby"
    }
}

### VPC Public Route - subnet-2 association
resource "aws_route_table_association" "public-standby" {
    route_table_id = aws_route_table.public.id
    subnet_id = aws_subnet.kitty-public-standby.id
}

### VPC Subnet 3 - private
resource "aws_subnet" "kitty-private" { 
    vpc_id = aws_vpc.kitty-app.id
    #availability_zone = "us-east-1f"
    availability_zone = data.aws_availability_zone.primary.id
    tags = {
        Name = "Private Subnet 1"
    }
    cidr_block = "10.0.3.0/24"
}

### VPC Private Route - subnet-3 association
resource "aws_route_table_association" "private" {
    route_table_id = aws_route_table.kitty-main.id
    subnet_id = aws_subnet.kitty-private.id
}

resource "aws_subnet" "kitty-private-standby" { 
    vpc_id = aws_vpc.kitty-app.id
    #availability_zone = "us-east-1f"
    availability_zone = data.aws_availability_zone.secondary.id
    map_public_ip_on_launch = true
    tags = {
        Name = "Private Subnet 1 Standby"
    }
    cidr_block = "10.0.4.0/24"
}

resource "aws_route_table_association" "private-standby" {
    route_table_id = aws_route_table.kitty-main.id
    subnet_id = aws_subnet.kitty-private-standby.id
}
