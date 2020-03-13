provider "aws" {
  region = var.region
}

### VPC Setup

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
}


resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

### Instance Setup

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "public" {
  name        = "public-squid"
  description = "Security Group for publicly-accessible instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3128
    to_port     = 3128
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "proxy" {

  instance_type = "t3.micro"
  ami           = var.amis[var.region]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = file(var.key_path)

  }

  vpc_security_group_ids = [aws_security_group.public.id]

  subnet_id = aws_subnet.public.id

  key_name = var.key_name

  user_data = file("./scripts/update.sh")

  provisioner "file" {
    source      = "./squid.conf"
    destination = "/tmp/squid.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo apt-get install -y squid | tee /tmp/squid.log",
      "sleep 30",
      "sudo cp /tmp/squid.conf /etc/squid/squid.conf",
      "sudo systemctl restart squid"
    ]
  }

}

resource "aws_instance" "sc_app" {

  depends_on = [aws_instance.proxy]

  connection {
    type                = "ssh"
    user                = "ubuntu"
    host                = self.private_ip
    private_key         = file(var.key_path)
    bastion_user        = "ubuntu"
    bastion_host        = aws_instance.proxy.public_ip
    bastion_private_key = file(var.key_path)

  }

  instance_type = "t3.micro"
  ami           = var.amis[var.region]

  subnet_id = aws_subnet.private.id

  key_name = var.key_name

  provisioner "remote-exec" {
    inline = [
      "sudo echo 'Acquire::http::Proxy \"http://${aws_instance.proxy.private_ip}:3128/\";' | sudo tee /etc/apt/apt.conf",
      "sudo echo 'Acquire::http::Proxy \"http://${aws_instance.proxy.private_ip}:3128/\";' | sudo tee /etc/apt/apt.conf",
      "sleep 30",
      "sudo apt-get update -y",
      "sudo apt-get install -y jq",
      "download_url=$(curl -x http://${aws_instance.proxy.private_ip}:3128 -s https://saucelabs.com/versions.json | jq -r '.\"Sauce Connect\".linux.download_url')",
      "curl -x http://${aws_instance.proxy.private_ip}:3128  -o ./sc.tar.gz $download_url",
      "tar -zxvf sc.tar.gz"
    ]
  }

}