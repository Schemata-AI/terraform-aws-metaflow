#!/bin/bash
# fck-nat user data script
# This script handles both fck-nat AMI and Amazon Linux 2 fallback

# Set hostname
hostnamectl set-hostname ${instance_id}

# Detect if this is a fck-nat AMI or Amazon Linux 2
if [[ -f /opt/fck-nat/fck-nat.sh ]]; then
    echo "Detected fck-nat AMI - using pre-configured fck-nat" | logger -t fck-nat-setup
    FCK_NAT_MODE="official"
else
    echo "Using Amazon Linux 2 - configuring NAT manually" | logger -t fck-nat-setup
    FCK_NAT_MODE="manual"
fi

# Configure NAT functionality
if [[ "$FCK_NAT_MODE" == "manual" ]]; then
    # Manual NAT configuration for Amazon Linux 2
    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
    sysctl -p
    
    # Configure iptables for NAT
    yum update -y
    yum install -y iptables-services
    
    # Enable NAT
    /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    /sbin/iptables -A FORWARD -i eth0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
    /sbin/iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT
    
    # Save iptables rules
    /sbin/service iptables save
    /sbin/chkconfig iptables on
    
    # Disable source/destination check (critical for NAT)
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --source-dest-check "{\"Value\": false}" --region us-west-1
else
    # fck-nat AMI is already configured, just ensure it's running
    systemctl enable fck-nat || true
    systemctl start fck-nat || true
fi

# Install CloudWatch agent for monitoring
yum install -y amazon-cloudwatch-agent

# Configure basic CloudWatch monitoring
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "metrics": {
    "namespace": "FckNat/Metaflow",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 300
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 300,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 300
      },
      "net": {
        "measurement": [
          "bytes_sent",
          "bytes_recv",
          "packets_sent",
          "packets_recv"
        ],
        "metrics_collection_interval": 300
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/fck-nat",
            "log_stream_name": "${instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Log startup completion
echo "fck-nat instance ${instance_id} configured successfully" | logger -t fck-nat-setup