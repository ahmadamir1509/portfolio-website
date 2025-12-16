# Use default VPC to avoid VPC limit exceeded error
data "aws_vpc" "default" {
  default = true
}

# Use default subnet
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = data.aws_availability_zones.available.names[0]
  default_for_az    = true
}
