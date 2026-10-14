terraform {
  required_version = "1.16.5"
  cloud {
    organization = "Dominionorg"
    workspaces {
      name = "Customer-inquiry-manager"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
}


resource "aws_vpc" "Drago_ro" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.Drago_ro.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "subnet_public"
  }
}

resource "aws_subnet" "subnet_prive_1" {
  vpc_id                  = aws_vpc.Drago_ro.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "subnet_prive_1"
  }
}

resource "aws_subnet" "subnet_prive_2" {
  vpc_id                  = aws_vpc.Drago_ro.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "subnet_prive_2"
  }
}


resource "aws_internet_gateway" "gw_Drago_ro" {
  vpc_id = aws_vpc.Drago_ro.id

  tags = {
    Name = "main"
  }
}


resource "aws_route_table" "public_rt_Draco_ro" {
  vpc_id = aws_vpc.Drago_ro.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_Drago_ro.id
  }
}

resource "aws_route_table_association" "rt_public_ass" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.public_rt_Draco_ro.id
}

resource "aws_network_acl" "nacl_public_Draco_ro" {
  vpc_id     = aws_vpc.Drago_ro.id
  subnet_ids = [aws_subnet.subnet_public.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 160
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}


resource "aws_network_acl" "nacl_prive1_Draco_ro" {
  vpc_id     = aws_vpc.Drago_ro.id
  subnet_ids = [aws_subnet.subnet_prive_1.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.2.0.0/24"
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.2.0.0/24"
    from_port  = 1024
    to_port    = 65535
  }
}

resource "aws_network_acl" "nacl_prive2_Draco_ro" {
  vpc_id     = aws_vpc.Drago_ro.id
  subnet_ids = [aws_subnet.subnet_prive_2.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.3.0.0/24"
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.3.0.0/24"
    from_port  = 1024
    to_port    = 65535
  }
}


resource "aws_security_group" "ec2_Draco_ro" {
  vpc_id = aws_vpc.Drago_ro.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_Draco_ro" {
  vpc_id = aws_vpc.Drago_ro.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_Draco_ro.id]
  }
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_Draco_ro.name
}


data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}



resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.subnet_public.id
  vpc_security_group_ids = [aws_security_group.ec2_Draco_ro.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  user_data              = <<-EOF
#!/bin/bash
yum update -y
yum install -y python3 python3-pip
pip3 install flask boto3 pymysql
# Crée l'application Flask
cat > /home/ec2-user/app.py << 'APPEOF'
import boto3, json, pymysql
from flask import Flask, request, jsonify
import os
app = Flask(__name__)
bedrock = boto3.client('bedrock-runtime', region_name='eu-west-1')
ses = boto3.client('ses', region_name='eu-west-1')
def analyze_inquiry(message):
response = bedrock.invoke_model(
modelId='anthropic.claude-3-haiku-20240307-v1:0',
body=json.dumps({
'anthropic_version': 'bedrock-2023-05-31',
'max_tokens': 200,
'messages': [{'role': 'user', 'content': f'Categorize this customer inquiry in one word
(BILLING/TECHNICAL/SALES/COMPLAINT/OTHER) and give urgency (LOW/MEDIUM/HIGH): {message}'}]
})
)
return json.loads(response['body'].read())['content'][0]['text']
@app.route('/inquiry', methods=['POST'])
def handle_inquiry():
data = request.json
analysis = analyze_inquiry(data.get('message', ''))
# Stocke dans RDS + envoie email via SES
return jsonify({'status': 'received', 'analysis': analysis})
if __name__ == '__main__':
app.run(host='0.0.0.0', port=80)
APPEOF
python3 /home/ec2-user/app.py &
EOF
  tags                   = { Name = "${var.project_name}-app" }
}


output "app" {
  value = "http://${aws_instance.app.public_ip}"
}

output "db_endpoint" {
  value = aws_db_instance.MySQL.endpoint
}