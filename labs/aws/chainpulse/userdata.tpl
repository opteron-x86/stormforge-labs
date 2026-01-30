#!/bin/bash
set -e

dnf update -y
dnf install -y python3 python3-pip postgresql16 awscli

pip3 install flask requests psycopg2-binary boto3

useradd -m -s /bin/bash chainpulse
mkdir -p /opt/chainpulse
chown chainpulse:chainpulse /opt/chainpulse

# Download application files from S3
aws s3 cp s3://${bucket_name}/app/app.py /opt/chainpulse/app.py
aws s3 cp s3://${bucket_name}/app/seed.sql /tmp/seed.sql

# Wait for RDS
echo "Waiting for database..."
for i in {1..30}; do
    if PGPASSWORD='${db_password}' psql -h ${db_host} -p ${db_port} -U ${db_user} -d ${db_name} -c "SELECT 1" > /dev/null 2>&1; then
        echo "Database ready"
        break
    fi
    sleep 10
done

# Populate database
PGPASSWORD='${db_password}' psql -h ${db_host} -p ${db_port} -U ${db_user} -d ${db_name} -f /tmp/seed.sql

chown -R chainpulse:chainpulse /opt/chainpulse
touch /var/log/chainpulse.log
chown chainpulse:chainpulse /var/log/chainpulse.log

cat > /etc/systemd/system/chainpulse.service << 'SERVICE'
[Unit]
Description=ChainPulse Price Oracle Aggregator
After=network.target

[Service]
Type=simple
User=chainpulse
WorkingDirectory=/opt/chainpulse
ExecStart=/usr/bin/python3 /opt/chainpulse/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable chainpulse
systemctl start chainpulse
