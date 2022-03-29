#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "argo-workflows-vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = tomap({
    "Name"                                      = "terraform-eks-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

resource "aws_subnet" "public-subnets" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.argo-workflows-vpc.id

  tags = tomap({
    "Name"                                      = "terraform-eks-node",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.argo-workflows-vpc.id

  tags = {
    Name = "terraform-eks-argo-workflows"
  }
}
wsl --shutdown
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.argo-workflows-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "route-table-association" {
  count = 2

  subnet_id      = aws_subnet.public-subnets.*.id[count.index]
  # subnet_id      = aws_vpc.argo-workflows-vpc.public_subnets.*.id[count.index]
  route_table_id = aws_route_table.route-table.id
}
