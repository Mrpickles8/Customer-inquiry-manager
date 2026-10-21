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

# Enregistrer les logs d'initialisation
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

set -euxo pipefail

echo "=== Starting EC2 initialization ==="

# 1. Démarrer et activer SSM Agent
if systemctl list-unit-files | grep -q '^amazon-ssm-agent.service'; then
  systemctl enable --now amazon-ssm-agent
else
  echo "SSM Agent service not found"
fi

# 2. Installer les dépendances Python
dnf install -y python3 python3-pip

python3 -m pip install flask boto3 pymysql

# 3. Créer l'application Flask
cat > /home/ec2-user/app.py << 'APPEOF'
import boto3
import json
from flask import Flask, request, jsonify

app = Flask(__name__)

bedrock = boto3.client('bedrock-runtime', region_name='eu-west-1')
ses = boto3.client('ses', region_name='eu-west-1')

def analyze_inquiry(message):
    response = bedrock.invoke_model(
        modelId='anthropic.claude-3-haiku-20240307-v1:0',
        body=json.dumps({
            'anthropic_version': 'bedrock-2023-05-31',
            'max_tokens': 200,
            'messages': [{
                'role': 'user',
                'content': (
                    'Categorize this customer inquiry in one word '
                    '(BILLING/TECHNICAL/SALES/COMPLAINT/OTHER) '
                    'and give urgency (LOW/MEDIUM/HIGH): '
                    + message
                )
            }]
        })
    )
    return json.loads(response['body'].read())['content'][0]['text']

@app.route('/health')
def health():
    return jsonify({'status': 'ok'}), 200

@app.route('/inquiry', methods=['POST'])
def handle_inquiry():
    data = request.get_json(silent=True) or {}
    message = data.get('message', '')

    if not isinstance(message, str) or not message.strip():
        return jsonify({'error': 'A non-empty message is required'}), 400

    try:
        analysis = analyze_inquiry(message)
        return jsonify({
            'status': 'received',
            'analysis': analysis
        })
    except Exception:
        app.logger.exception("Inquiry analysis failed")
        return jsonify({'error': 'Analysis failed'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
APPEOF

# 4. Donner à ec2-user la propriété du fichier
chown ec2-user:ec2-user /home/ec2-user/app.py
chmod 644 /home/ec2-user/app.py

# 5. Créer un service systemd pour Flask
cat > /etc/systemd/system/customer-inquiry.service << 'SERVICEEOF'
[Unit]
Description=Customer Inquiry Flask Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/ec2-user
Environment=PYTHONUNBUFFERED=1
ExecStart=/usr/bin/python3 /home/ec2-user/app.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

# 6. Activer et démarrer l'application
systemctl daemon-reload
systemctl enable --now customer-inquiry.service

# 7. Attendre que Flask réponde localement
for i in $(seq 1 30); do
  if curl -fsS --max-time 2 http://127.0.0.1/health; then
    echo
    echo "Local health check passed"
    break
  fi

  echo "Waiting for Flask startup: attempt $i/30"
  sleep 2
done

# 8. Vérifier que le service fonctionne
systemctl --no-pager --full status customer-inquiry.service
systemctl --no-pager --full status amazon-ssm-agent || true

echo "=== EC2 initialization finished ==="
EOF
}

output "app_public_ip" {
  value = aws_instance.app.public_ip
}


output "app" {
  value = "http://${aws_instance.app.public_ip}"
}

output "db_endpoint" {
  value = aws_db_instance.MySQL.endpoint
}