provider "aws" {
  region = "us-east-2"  # Specify your desired AWS region
}

# Variables
variable "instance1_name" {
  description = "Name for EC2 instance 1"
  default     = "Instance1"
}

variable "instance2_name" {
  description = "Name for EC2 instance 2"
  default     = "Instance2"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Create Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Create Subnets
resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"  # Specify AZ 1
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"  # Specify AZ 2
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet2"
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2a"  # Specify AZ 1

  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"  # Specify AZ 2

  tags = {
    Name = "PrivateSubnet2"
  }
}

# Create Security Groups
resource "aws_security_group" "web_server" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_server" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.web_server.id]
  }
}

# Create EC2 Instances
resource "aws_instance" "instance1" {
  ami           = "ami-0c55b159cbfafe1f0"  # Specify your desired AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public1.id
  security_groups = [aws_security_group.web_server.id]
  tags = {
    Name = var.instance1_name
  }
}

resource "aws_instance" "instance2" {
  ami           = "ami-0c55b159cbfafe1f0"  # Specify your desired AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public2.id
  security_groups = [aws_security_group.web_server.id]
  tags = {
    Name = var.instance2_name
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "my-db-subnet-group2"
  subnet_ids  = [aws_subnet.private1.id, aws_subnet.private2.id]  # Adjust subnet IDs as needed
  description = "My DB Subnet Group"
}

# Create RDS Instance
 #Create RDS Instance
resource "aws_db_instance" "main" {
  identifier           = "myrds3"
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "5.7"  # Example: Choose a supported engine version
  instance_class       = "db.t3.micro"  # Example: Choose a supported instance class
  username             = "admin"
  password             = "your_password"
  db_name              = "your_database_name"
  publicly_accessible  = false
  skip_final_snapshot  = false
  backup_retention_period = 7
  multi_az             = false
  vpc_security_group_ids = [aws_security_group.db_server.id]
  db_subnet_group_name = aws_db_subnet_group.main.name
  license_model     = "general-public-license"
}

# Outputs
output "instance1_public_ip" {
  value = aws_instance.instance1.public_ip
}

output "instance2_public_ip" {
  value = aws_instance.instance2.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}
